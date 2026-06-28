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

  # Twilio routes/v2 Inbound Processing Region binding for a claimed phone number.
  # Keyed by E.164 phone number or its PN sid; account resolved from HTTP Basic auth.
  class RoutesV2PhoneNumber
    ATTRIBUTES = %w[
      sid phone_number account_sid friendly_name voice_region url
      date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end
end
