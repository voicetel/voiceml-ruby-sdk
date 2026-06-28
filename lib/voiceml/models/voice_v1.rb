# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Twilio Voice v1 (voice.twilio.com/v1) resources.
  #
  # Distinct from the 2010-04-01 surface in two ways:
  #   - No `/Accounts/{AccountSid}` segment — account resolves from HTTP Basic auth.
  #   - List pages carry a `meta` envelope (URLs + page/page_size + key) instead of
  #     the flat Twilio2010 `next_page_uri` shape.
  #
  # Six resources implemented for v0.9.0:
  #   - ByocTrunk (BY...)            — bring-your-own-carrier trunk
  #   - ConnectionPolicy (NY...)     — origination policy
  #   - ConnectionPolicyTarget (NE...)
  #   - Settings                     — DialingPermissions inheritance
  #   - SourceIpMapping (IB...)      — bind IpRecord -> SipDomain
  #   - IpRecord (IL...)             — standalone allowed source IP

  # Shared `meta` envelope for `/v1/*` list responses.
  module V1Pageable
    META_FIELDS = %w[first_page_url next_page_url previous_page_url url page page_size key].freeze

    META_FIELDS.each { |f| attr_reader f.to_sym }

    def assign_meta_fields(hash)
      meta = hash['meta'] || {}
      META_FIELDS.each { |f| instance_variable_set("@#{f}", meta[f]) }
    end
  end

  # VoiceV1IpRecord — `IL...`.
  class VoiceV1IpRecord
    ATTRIBUTES = %w[
      account_sid sid friendly_name ip_address cidr_prefix_length
      date_created date_updated url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class VoiceV1IpRecordList
    include V1Pageable
    attr_reader :ip_records
    def initialize(hash = {})
      assign_meta_fields(hash)
      @ip_records = (hash['ip_records'] || []).map { |h| VoiceV1IpRecord.from_hash(h) }
    end
  end

  # VoiceV1SourceIpMapping — `IB...`. Binds an IpRecord to a SipDomain.
  class VoiceV1SourceIpMapping
    ATTRIBUTES = %w[
      sid ip_record_sid sip_domain_sid date_created date_updated url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class VoiceV1SourceIpMappingList
    include V1Pageable
    attr_reader :source_ip_mappings
    def initialize(hash = {})
      assign_meta_fields(hash)
      @source_ip_mappings = (hash['source_ip_mappings'] || []).map { |h| VoiceV1SourceIpMapping.from_hash(h) }
    end
  end

  # VoiceV1ByocTrunk — `BY...`. Bring-your-own-carrier trunk.
  class VoiceV1ByocTrunk
    ATTRIBUTES = %w[
      account_sid sid friendly_name voice_url voice_method voice_fallback_url
      voice_fallback_method status_callback_url status_callback_method
      cnam_lookup_enabled connection_policy_sid from_domain_sid
      date_created date_updated url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class VoiceV1ByocTrunkList
    include V1Pageable
    attr_reader :byoc_trunks
    def initialize(hash = {})
      assign_meta_fields(hash)
      @byoc_trunks = (hash['byoc_trunks'] || []).map { |h| VoiceV1ByocTrunk.from_hash(h) }
    end
  end

  # VoiceV1ConnectionPolicy — `NY...`.
  class VoiceV1ConnectionPolicy
    ATTRIBUTES = %w[
      account_sid sid friendly_name date_created date_updated url links
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class VoiceV1ConnectionPolicyList
    include V1Pageable
    attr_reader :connection_policies
    def initialize(hash = {})
      assign_meta_fields(hash)
      @connection_policies = (hash['connection_policies'] || []).map { |h| VoiceV1ConnectionPolicy.from_hash(h) }
    end
  end

  # VoiceV1ConnectionPolicyTarget — `NE...`. Scoped to a parent ConnectionPolicy.
  class VoiceV1ConnectionPolicyTarget
    ATTRIBUTES = %w[
      account_sid connection_policy_sid sid friendly_name target priority weight
      enabled date_created date_updated url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class VoiceV1ConnectionPolicyTargetList
    include V1Pageable
    attr_reader :targets
    def initialize(hash = {})
      assign_meta_fields(hash)
      @targets = (hash['targets'] || []).map { |h| VoiceV1ConnectionPolicyTarget.from_hash(h) }
    end
  end

  # VoiceV1DialingPermissionsSettings — `/v1/Settings`.
  class VoiceV1DialingPermissionsSettings
    ATTRIBUTES = %w[dialing_permissions_inheritance url].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end
end
