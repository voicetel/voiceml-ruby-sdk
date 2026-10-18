# frozen_string_literal: true

require 'webmock/rspec'
require 'voiceml'

WebMock.disable_net_connect!(allow_localhost: false)

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.order = :random
  Kernel.srand config.seed
end

# A canonical fake account SID for fixture URLs.
unless defined?(ACCOUNT_SID)
  ACCOUNT_SID = 'AC00000000000000000000000000000001'
  API_KEY     = 'test-key'
end

def base_url
  'https://voiceml.voicetel.com'
end

def accounts_path(*parts, suffix: '.json')
  "/2010-04-01/Accounts/#{ACCOUNT_SID}/#{parts.join('/')}#{suffix}"
end

def basic_auth_header
  encoded = Base64.strict_encode64("#{ACCOUNT_SID}:#{API_KEY}")
  "Basic #{encoded}"
end

require 'base64' # bundled gem since Ruby 3.4; declared in the Gemfile test group
