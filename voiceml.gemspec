# frozen_string_literal: true

require_relative 'lib/voiceml/version'

Gem::Specification.new do |spec|
  spec.name          = 'voiceml'
  spec.version       = VoiceML::VERSION
  spec.authors       = ['VoiceTel']
  spec.email         = ['support@voicetel.com']

  spec.summary       = 'Official Ruby SDK for the VoiceML REST API'
  spec.description   = 'Twilio-compatible voice + AMD service from VoiceTel'
  spec.homepage      = 'https://voiceml.voicetel.com'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.0'

  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']

  spec.metadata = {
    'documentation_uri' => 'https://voiceml.voicetel.com',
    'source_code_uri'   => 'https://voiceml.voicetel.com',
    'rubygems_mfa_required' => 'true'
  }

  spec.add_development_dependency 'rake',    '~> 13.0'
  spec.add_development_dependency 'rspec',   '~> 3.13'
  spec.add_development_dependency 'webmock', '~> 3.23'
end
