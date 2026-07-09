# frozen_string_literal: true

require_relative 'common'
require_relative 'voice_v1' # V1Pageable lives here; Messaging v1 reuses the same `meta` envelope

module VoiceML
  # Twilio Messaging v1 (messaging.twilio.com/v1) resources.
  #
  # A Messaging Service (`MG...`) shares the `/v1/Services` path shape with the
  # Conversations Service (`IS...`); the two are disambiguated on the wire by host
  # (`messaging.voicetel.com` vs `conversations.voicetel.com`). This SDK routes
  # `client.messaging_v1.*` at the messaging host automatically — see VoiceML::Hosts.

  # MessagingService — `MG...`. The feature-toggle fields are accept-and-echo on
  # VoiceML; the service's operative role is gating scheduled sends.
  class MessagingService
    ATTRIBUTES = %w[
      sid account_sid friendly_name date_created date_updated
      inbound_request_url inbound_method fallback_url fallback_method status_callback
      sticky_sender mms_converter smart_encoding scan_message_content
      fallback_to_long_code area_code_geomatch synchronous_validation validity_period
      url usecase use_inbound_webhook_on_number
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # List envelope for `GET /v1/Services` on the messaging host.
  class MessagingServiceList
    include V1Pageable
    attr_reader :services
    def initialize(hash = {})
      assign_meta_fields(hash)
      @services = (hash['services'] || []).map { |h| MessagingService.from_hash(h) }
    end
  end
end
