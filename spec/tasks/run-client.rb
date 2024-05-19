# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../ports/dsl/maritaca-ai'

begin
  client = Maritaca.new(credentials: { api_key: nil })

  client.chat_inference(
    { model: 'sabia-2-medium',
      chat_mode: true,
      messages: [{ role: 'user', content: 'Oi!' }] }
  )
rescue StandardError => e
  raise "Unexpected error: #{e.class}" unless e.instance_of?(Maritaca::Errors::MissingAPIKeyError)
end

client = Maritaca.new(
  credentials: { api_key: ENV.fetch('MARITACA_API_KEY', nil) }
)

result = client.chat_inference(
  { model: 'sabia-2-medium',
    chat_mode: true,
    messages: [{ role: 'user', content: 'Oi!' }] }
)

puts result

puts '-' * 20

client = Maritaca.new(
  credentials: { api_key: ENV.fetch('MARITACA_API_KEY', nil) },
  options: { server_sent_events: true }
)

result = client.chat_inference(
  { model: 'sabia-2-medium',
    stream: true,
    chat_mode: true,
    messages: [{ role: 'user', content: 'Oi!' }] }
) do |event, _parsed, _raw|
  print event['text'] unless event['text'].nil?
end

puts ''

puts '-' * 20

puts result

puts '-' * 20

result = client.chat_inference(
  { model: 'sabia-2-medium',
    stream: false,
    chat_mode: true,
    messages: [{ role: 'user', content: 'Oi!' }] }
) do |event, _parsed, _raw|
  print event['answer'] unless event['answer'].nil?
end

puts ''

puts '-' * 20

puts result
