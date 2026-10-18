# frozen_string_literal: true

require_relative 'transport'
require_relative 'hosts'
require_relative 'resources/calls'
require_relative 'resources/conferences'
require_relative 'resources/queues'
require_relative 'resources/applications'
require_relative 'resources/recordings'
require_relative 'resources/incoming_phone_numbers'
require_relative 'resources/notifications'
require_relative 'resources/diagnostics'
require_relative 'resources/messages'
require_relative 'resources/sip'
require_relative 'resources/routes_v2'
require_relative 'resources/voice_v1'
require_relative 'resources/conversations_v1'
require_relative 'resources/assistants_v1'
require_relative 'resources/messaging_v1'
require_relative 'resources/pricing'
require_relative 'resources/accounts'
require_relative 'resources/outgoing_caller_ids'
require_relative 'resources/exports'
require_relative 'resources/usage_records'
require_relative 'resources/transcriptions'
require_relative 'resources/monitor_v1'

module VoiceML
  # Synchronous client for the VoiceML REST API.
  #
  # VoiceML uses HTTP Basic auth: the `account_sid` (Twilio-format `AC` + 32 hex) is the
  # username and `api_key` is the password, in the same HTTP Basic positions twilio-ruby
  # uses. VoiceML issues its own credentials — the AccountSid plus a VoiceML API key;
  # Twilio-issued credentials do not work here.
  #
  # A client without an `api_key:` is a credential-less diagnostics client: only
  # {VoiceML::DiagnosticsResource} calls work (the spec marks them `security: []`);
  # anything authenticated raises {VoiceML::ConfigurationError}.
  #
  # The client is thread-safe: requests may be issued from any number of threads,
  # each holding its own connection per host.
  #
  # @example
  #   client = VoiceML::Client.new(account_sid: 'AC...', api_key: '...')
  #   call = client.calls.create(
  #     to: '+14155550100',
  #     from: '+14155550101',
  #     url: 'https://example.com/handler'
  #   )
  #   puts call.sid, call.status
  class Client
    attr_reader :calls, :conferences, :queues, :applications, :recordings,
                :incoming_phone_numbers, :notifications, :diagnostics, :messages,
                :sip, :routes_v2, :voice_v1, :conversations_v1, :assistants_v1,
                :messaging_v1, :pricing, :accounts, :outgoing_caller_ids, :exports,
                :usage_records, :transcriptions, :monitor_alerts

    # @param account_sid [String] Twilio-format AccountSid (`AC` + 32 hex).
    # @param api_key     [String, nil] per-tenant VoiceML API key. Pass either `api_key:` or
    #   the Twilio-compatible alias `auth_token:` (not both — `ArgumentError` if you do).
    #   Omit both for a credential-less diagnostics-only client.
    # @param auth_token  [String, nil] Twilio-compatible alias for `api_key`. Lets
    #   credential-passing code written for twilio-ruby keep its call shape; the key
    #   itself must be a VoiceML API key.
    # @param base_url    [String] server base URL. Defaults to `https://voiceml.voicetel.com`.
    # @param timeout     [Numeric] per-request connect/read/write timeout in seconds. Defaults to 30.
    # @param max_retries [Integer] retry attempts. Idempotent requests (GET/HEAD/PUT/DELETE)
    #   retry on 429/5xx and transport errors; POST/PATCH retry only on 429 and
    #   connect-phase failures. Defaults to 2.
    # @param user_agent  [String, nil] override the `User-Agent` header. Defaults to
    #   `"voiceml-ruby/#{VERSION}"`.
    # @param http_client [Net::HTTP, #call, nil] a `Net::HTTP` used for its own host, or a
    #   factory `->(uri) { Net::HTTP.new(uri.host, uri.port) }` supplying every
    #   connection. Caller-supplied connections are never finished by the SDK; hosts the
    #   object/factory does not cover fall back to SDK-managed connections.
    # @param messaging_base_url     [String, nil] override the host for `messaging_v1`. Defaults to
    #   the `messaging.*.voicetel.com` subdomain derived from `base_url` (else `base_url` itself).
    # @param conversations_base_url [String, nil] override the host for `conversations_v1`. Defaults
    #   to the `conversations.*.voicetel.com` subdomain derived from `base_url` (else `base_url`).
    def initialize(account_sid: nil, api_key: nil, auth_token: nil,
                   base_url: Transport::DEFAULT_BASE_URL,
                   timeout: Transport::DEFAULT_TIMEOUT,
                   max_retries: Transport::DEFAULT_MAX_RETRIES,
                   user_agent: nil, http_client: nil,
                   messaging_base_url: nil, conversations_base_url: nil)
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

      # VoiceML mirrors Twilio's product-per-subdomain model: the whole Conversations group
      # rides `conversations.voicetel.com` and Messaging Service rides `messaging.voicetel.com`,
      # while everything else stays on the default host. See VoiceML::Hosts.
      _default, messaging_host, conversations_host =
        Hosts.resolve_product_base_urls(base_url,
                                        messaging_base_url: messaging_base_url,
                                        conversations_base_url: conversations_base_url)
      messaging_transport     = ScopedTransport.new(@transport, messaging_host)
      conversations_transport = ScopedTransport.new(@transport, conversations_host)

      @calls                  = CallsResource.new(@transport)
      @conferences            = ConferencesResource.new(@transport)
      @queues                 = QueuesResource.new(@transport)
      @applications           = ApplicationsResource.new(@transport)
      @recordings             = RecordingsResource.new(@transport)
      @incoming_phone_numbers = IncomingPhoneNumbersResource.new(@transport)
      @notifications          = NotificationsResource.new(@transport)
      @diagnostics            = DiagnosticsResource.new(@transport)
      @messages               = MessagesResource.new(@transport)
      @sip                    = SipResource.new(@transport)
      @routes_v2              = RoutesV2Resource.new(@transport)
      @voice_v1               = VoiceV1Resource.new(@transport)
      @conversations_v1       = ConversationsV1Resource.new(conversations_transport)
      @assistants_v1          = AssistantsV1Resource.new(@transport)
      @messaging_v1           = MessagingV1Resource.new(messaging_transport)
      @pricing                = PricingResource.new(@transport)
      @accounts               = AccountsResource.new(@transport)
      @outgoing_caller_ids    = OutgoingCallerIdsResource.new(@transport)
      @exports                = ExportsResource.new(@transport)
      @usage_records          = UsageRecordsResource.new(@transport)
      @transcriptions         = TranscriptionsResource.new(@transport)
      @monitor_alerts         = MonitorAlertsResource.new(@transport)
    end

    def account_sid
      @transport.account_sid
    end

    def base_url
      @transport.base_url
    end

    # Close SDK-managed idle connections. The client remains usable.
    def close
      @transport.close
    end

    # A redacted dump: never includes the API key.
    def inspect
      "#<#{self.class.name} account_sid=#{account_sid} base_url=#{base_url}>"
    end
    alias to_s inspect
  end
end
