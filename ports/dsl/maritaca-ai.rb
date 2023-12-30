# frozen_string_literal: true

require_relative '../../static/gem'
require_relative '../../controllers/client'

module Maritaca
  def self.new(...)
    Controllers::Client.new(...)
  end

  def self.version
    Maritaca::GEM[:version]
  end
end
