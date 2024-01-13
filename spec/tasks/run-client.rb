# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../ports/dsl/maritaca-ai'

begin
  client = Maritaca.new(credentials: { api_key: nil })

  client.chat_inference(
    { model: 'maritalk',
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
  { model: 'maritalk',
    chat_mode: true,
    messages: [{ role: 'user', content: 'Oi!' }] }
)

puts result
