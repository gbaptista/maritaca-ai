# frozen_string_literal: true

require_relative 'static/gem'

Gem::Specification.new do |spec|
  spec.name    = Maritaca::GEM[:name]
  spec.version = Maritaca::GEM[:version]
  spec.authors = [Maritaca::GEM[:author]]

  spec.summary = Maritaca::GEM[:summary]
  spec.description = Maritaca::GEM[:description]

  spec.homepage = Maritaca::GEM[:github]

  spec.license = Maritaca::GEM[:license]

  spec.required_ruby_version = Gem::Requirement.new(">= #{Maritaca::GEM[:ruby]}")

  spec.metadata['allowed_push_host'] = Maritaca::GEM[:gem_server]

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = Maritaca::GEM[:github]

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end

  spec.require_paths = ['ports/dsl']

  spec.add_dependency 'faraday', '~> 2.9'
  spec.add_dependency 'faraday-typhoeus', '~> 1.1'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
