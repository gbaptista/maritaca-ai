# frozen_string_literal: true

module Maritaca
  module Errors
    class MaritacaError < StandardError
      def initialize(message = nil)
        super(message)
      end
    end

    class MissingAPIKeyError < MaritacaError; end
    class BlockWithoutServerSentEventsError < MaritacaError; end

    class RequestError < MaritacaError
      attr_reader :request, :payload

      def initialize(message = nil, request: nil, payload: nil)
        @request = request
        @payload = payload

        super(message)
      end
    end
  end
end
