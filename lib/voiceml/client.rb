# frozen_string_literal: true

require_relative 'transport'
require_relative 'resources/calls'
require_relative 'resources/conferences'
require_relative 'resources/queues'
require_relative 'resources/applications'
require_relative 'resources/recordings'
require_relative 'resources/incoming_phone_numbers'
require_relative 'resources/notifications'
require_relative 'resources/diagnostics'

module VoiceML
  # Synchronous client for the VoiceML REST API.
  #
  # VoiceML uses HTTP Basic auth: the `account_sid` (Twilio-format `AC` + 32 hex) is the
  # username and `api_key` is the password. Drop-in compatible with the Twilio Ruby SDK
  # constructor signature.
  #
  # @example
  #   client = VoiceML::Client.new(account_sid: 'AC...', api_key: '...')
  #   call = client.calls.create(
  #     to: '+18005551234',
  #     from: '+18005550000',
  #     url: 'https://example.com/twiml'
  #   )
  #   puts call.sid, call.status
  class Client
    attr_reader :calls, :conferences, :queues, :applications, :recordings,
                :incoming_phone_numbers, :notifications, :diagnostics

    # @param account_sid [String] Twilio-format AccountSid (`AC` + 32 hex).
    # @param api_key     [String, nil] per-tenant API key. Pass either `api_key:` or the
    #   Twilio-compatible alias `auth_token:` (not both — `ArgumentError` if you do).
    # @param auth_token  [String, nil] Twilio-compatible alias for `api_key`. Lets twilio-ruby
    #   code (`VoiceML::Client.new(account_sid: sid, auth_token: token)`) work unchanged.
    # @param base_url    [String] server base URL. Defaults to `https://voiceml.voicetel.com`.
    # @param timeout     [Numeric] per-request timeout in seconds. Defaults to 30.
    # @param max_retries [Integer] retry attempts for 429/5xx and transport errors. Defaults to 2.
    # @param user_agent  [String, nil] override the `User-Agent` header. Defaults to
    #   `"voiceml-ruby/#{VERSION}"`.
    def initialize(account_sid:, api_key: nil, auth_token: nil,
                   base_url: Transport::DEFAULT_BASE_URL,
                   timeout: Transport::DEFAULT_TIMEOUT,
                   max_retries: Transport::DEFAULT_MAX_RETRIES,
                   user_agent: nil, http_client: nil)
      if !api_key.nil? && !auth_token.nil?
        raise ArgumentError, 'pass either api_key: or auth_token:, not both'
      end

      resolved_key = api_key || auth_token

      @transport = Transport.new(
        account_sid: account_sid,
        api_key:     resolved_key,
        base_url:    base_url,
        timeout:     timeout,
        max_retries: max_retries,
        user_agent:  user_agent,
        http_client: http_client
      )

      @calls                  = CallsResource.new(@transport)
      @conferences            = ConferencesResource.new(@transport)
      @queues                 = QueuesResource.new(@transport)
      @applications           = ApplicationsResource.new(@transport)
      @recordings             = RecordingsResource.new(@transport)
      @incoming_phone_numbers = IncomingPhoneNumbersResource.new(@transport)
      @notifications          = NotificationsResource.new(@transport)
      @diagnostics            = DiagnosticsResource.new(@transport)
    end

    def account_sid
      @transport.account_sid
    end

    def base_url
      @transport.base_url
    end
  end
end
