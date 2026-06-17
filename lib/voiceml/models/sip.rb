# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # SIP Trunking resources — the Twilio-compatible /SIP/* REST surface.
  #
  # Three top-level sub-trees:
  #   - Domains (SD...) — SIP ingress endpoints
  #   - CredentialLists (CL...) holding Credentials (CR...) — SIP-digest auth
  #   - IpAccessControlLists (AL...) holding IpAddresses (IP...) — CIDR allowlists
  #
  # Mappings bind CredentialLists / IpAccessControlLists to a SipDomain via
  # four endpoints: historical (no /Auth/) + /Auth/Calls/ + /Auth/Registrations/.

  # SipDomain — `SD...` resource.
  class SipDomain
    ATTRIBUTES = %w[
      sid account_sid domain_name api_version friendly_name auth_type
      voice_url voice_method voice_fallback_url voice_fallback_method
      voice_status_callback_url voice_status_callback_method
      sip_registration emergency_calling_enabled secure
      byoc_trunk_sid emergency_caller_sid
      date_created date_updated uri subresource_uris
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class SipDomainList
    include Pageable
    attr_reader :domains
    def initialize(hash = {})
      assign_page_fields(hash)
      @domains = (hash['domains'] || []).map { |h| SipDomain.from_hash(h) }
    end
  end

  # SipCredentialList — `CL...`.
  class SipCredentialList
    ATTRIBUTES = %w[
      sid account_sid friendly_name date_created date_updated uri subresource_uris
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class SipCredentialListList
    include Pageable
    attr_reader :credential_lists
    def initialize(hash = {})
      assign_page_fields(hash)
      @credential_lists = (hash['credential_lists'] || []).map { |h| SipCredentialList.from_hash(h) }
    end
  end

  # SipCredential — `CR...`. Password is write-only (never returned).
  class SipCredential
    ATTRIBUTES = %w[
      sid account_sid credential_list_sid username
      date_created date_updated uri
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # SipCredentialListPage — spec name is `SipCredentialListPage` but it's a page of
  # CREDENTIALS (not credential-lists), mirroring Twilio.
  class SipCredentialListPage
    include Pageable
    attr_reader :credentials
    def initialize(hash = {})
      assign_page_fields(hash)
      @credentials = (hash['credentials'] || []).map { |h| SipCredential.from_hash(h) }
    end
  end

  # SipIpAccessControlList — `AL...`.
  class SipIpAccessControlList
    ATTRIBUTES = %w[
      sid account_sid friendly_name date_created date_updated uri subresource_uris
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class SipIpAccessControlListList
    include Pageable
    attr_reader :ip_access_control_lists
    def initialize(hash = {})
      assign_page_fields(hash)
      @ip_access_control_lists = (hash['ip_access_control_lists'] || []).map { |h| SipIpAccessControlList.from_hash(h) }
    end
  end

  # SipIpAddress — `IP...`.
  class SipIpAddress
    ATTRIBUTES = %w[
      sid account_sid ip_access_control_list_sid
      friendly_name ip_address cidr_prefix_length
      date_created date_updated uri
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class SipIpAddressList
    include Pageable
    attr_reader :ip_addresses
    def initialize(hash = {})
      assign_page_fields(hash)
      @ip_addresses = (hash['ip_addresses'] || []).map { |h| SipIpAddress.from_hash(h) }
    end
  end

  # SipDomainMapping — round-trip shape for every domain mapping sub-resource.
  # `sid` echoes the bound resource (CL... for credential mappings, AL... for IP-ACL);
  # `domain_sid` records which domain the binding is attached to.
  class SipDomainMapping
    ATTRIBUTES = %w[
      sid account_sid friendly_name domain_sid date_created date_updated uri
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class SipCredentialListMappingList
    include Pageable
    attr_reader :credential_list_mappings
    def initialize(hash = {})
      assign_page_fields(hash)
      @credential_list_mappings = (hash['credential_list_mappings'] || []).map { |h| SipDomainMapping.from_hash(h) }
    end
  end

  class SipIpAccessControlListMappingList
    include Pageable
    attr_reader :ip_access_control_list_mappings
    def initialize(hash = {})
      assign_page_fields(hash)
      @ip_access_control_list_mappings = (hash['ip_access_control_list_mappings'] || []).map { |h| SipDomainMapping.from_hash(h) }
    end
  end
end
