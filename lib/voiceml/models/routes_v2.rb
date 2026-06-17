# frozen_string_literal: true

module VoiceML
  # Twilio routes/v2 Inbound Processing Region binding. SID is `QQ...`.
  # Keyed by SIP domain name (not the SipDomain SID).
  class RoutesV2SipDomain
    ATTRIBUTES = %w[
      sid sip_domain account_sid friendly_name voice_region url
      date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end
end
