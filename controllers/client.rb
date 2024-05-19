# frozen_string_literal: true

require 'event_stream_parser'
require 'faraday'
require 'faraday/typhoeus'
require 'json'

require_relative '../components/errors'

module Maritaca
  module Controllers
    class Client
      DEFAULT_ADDRESS = 'https://chat.maritaca.ai'

      ALLOWED_REQUEST_OPTIONS = %i[timeout open_timeout read_timeout write_timeout].freeze

      DEFAULT_FARADAY_ADAPTER = :typhoeus

      def initialize(config)
        @api_key = config.dig(:credentials, :api_key)
        @server_sent_events = config.dig(:options, :server_sent_events)

        @address = if config[:credentials][:address].nil? || config[:credentials][:address].to_s.strip.empty?
                     "#{DEFAULT_ADDRESS}/"
                   else
                     "#{config[:credentials][:address].to_s.sub(%r{/$}, '')}/"
                   end

        if @api_key.nil? && @address == "#{DEFAULT_ADDRESS}/"
          raise Errors::MissingAPIKeyError, 'Missing API Key, which is required.'
        end

        @request_options = config.dig(:options, :connection, :request)

        @request_options = if @request_options.is_a?(Hash)
                             @request_options.select do |key, _|
                               ALLOWED_REQUEST_OPTIONS.include?(key)
                             end
                           else
                             {}
                           end

        @faraday_adapter = config.dig(:options, :connection, :adapter) || DEFAULT_FARADAY_ADAPTER
      end

      def chat_inference(payload, server_sent_events: nil, &callback)
        request('api/chat/inference', payload, server_sent_events:, &callback)
      end

      def request(path, payload = nil, server_sent_events: nil, request_method: 'POST', &callback)
        server_sent_events_enabled = server_sent_events.nil? ? @server_sent_events : server_sent_events
        url = "#{@address}#{path}"

        if !callback.nil? && !server_sent_events_enabled
          raise Errors::BlockWithoutServerSentEventsError,
                'You are trying to use a block without Server Sent Events (SSE) enabled.'
        end

        results = []

        method_to_call = request_method.to_s.strip.downcase.to_sym

        response = Faraday.new(request: @request_options) do |faraday|
          faraday.adapter @faraday_adapter
          faraday.response :raise_error
        end.send(method_to_call) do |request|
          request.url url
          request.headers['Content-Type'] = 'application/json'

          request.headers['authorization'] = "Key #{@api_key}" unless @api_key.nil?

          request.body = payload.to_json unless payload.nil?

          if server_sent_events_enabled
            parser = EventStreamParser::Parser.new

            partial_json = ''

            request.options.on_data = proc do |chunk, bytes, env|
              if env && env.status != 200
                raise_error = Faraday::Response::RaiseError.new
                raise_error.on_complete(env.merge(body: chunk))
              end

              partial_json += chunk

              parsed_json = safe_parse_json(partial_json)

              if parsed_json
                result = {
                  event: parsed_json,
                  raw: { chunk:, bytes:, env: }
                }

                callback.call(result[:event], result[:parsed], result[:raw]) unless callback.nil?

                results << result

                partial_json = ''
              end

              parser.feed(chunk) do |type, data, id, reconnection_time|
                parsed_data = safe_parse_json(data)

                unless parsed_data.nil?
                  result = {
                    event: parsed_data,
                    parsed: { type:, data:, id:, reconnection_time: },
                    raw: { chunk:, bytes:, env: }
                  }

                  callback.call(result[:event], result[:parsed], result[:raw]) unless callback.nil?

                  results << result
                end
              end
            end
          end
        end

        return safe_parse_json_with_fallback_to_raw(response.body) unless server_sent_events_enabled

        results.map { |result| result[:event] }
      rescue Faraday::ServerError => e
        raise Errors::RequestError.new(e.message, request: e, payload:)
      end

      def safe_parse_json_with_fallback_to_raw(raw)
        raw.to_s.lstrip.start_with?('{', '[') ? JSON.parse(raw) : raw
      rescue JSON::ParserError
        raw
      end

      def safe_parse_json(raw)
        raw.to_s.lstrip.start_with?('{', '[') ? JSON.parse(raw) : nil
      rescue JSON::ParserError
        nil
      end
    end
  end
end
