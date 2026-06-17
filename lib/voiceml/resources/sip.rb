# frozen_string_literal: true

require_relative 'base'
require_relative '../models/sip'

module VoiceML
  # `client.sip` — top-level SIP Trunking holder.
  class SipResource
    attr_reader :domains, :credential_lists, :ip_access_control_lists

    def initialize(transport)
      @domains = SipDomainsResource.new(transport)
      @credential_lists = SipCredentialListsResource.new(transport)
      @ip_access_control_lists = SipIpAccessControlListsResource.new(transport)
    end
  end

  # /SIP/Domains plus the four mapping endpoints.
  class SipDomainsResource < BaseResource
    DOMAIN_FIELDS = {
      'FriendlyName' => :friendly_name,
      'VoiceUrl' => :voice_url,
      'VoiceMethod' => :voice_method,
      'VoiceFallbackUrl' => :voice_fallback_url,
      'VoiceFallbackMethod' => :voice_fallback_method,
      'VoiceStatusCallbackUrl' => :voice_status_callback_url,
      'VoiceStatusCallbackMethod' => :voice_status_callback_method,
      'SipRegistration' => :sip_registration,
      'Secure' => :secure,
      'EmergencyCallingEnabled' => :emergency_calling_enabled,
      'ByocTrunkSid' => :byoc_trunk_sid,
      'EmergencyCallerSid' => :emergency_caller_sid
    }.freeze

    PAGE_FIELDS = { 'Page' => :page, 'PageSize' => :page_size, 'PageToken' => :page_token }.freeze

    def list(**kwargs)
      SipDomainList.new(@transport.request(:get, path('SIP', 'Domains'), params: form_params(PAGE_FIELDS, kwargs)))
    end

    def create(domain_name:, **kwargs)
      body = { 'DomainName' => domain_name }.merge(form_params(DOMAIN_FIELDS, kwargs))
      SipDomain.from_hash(@transport.request(:post, path('SIP', 'Domains'), form: body))
    end

    def fetch(domain_sid)
      SipDomain.from_hash(@transport.request(:get, path('SIP', 'Domains', domain_sid)))
    end

    def update(domain_sid, **kwargs)
      SipDomain.from_hash(@transport.request(:post, path('SIP', 'Domains', domain_sid), form: form_params(DOMAIN_FIELDS, kwargs)))
    end

    def delete(domain_sid)
      @transport.request(:delete, path('SIP', 'Domains', domain_sid))
      nil
    end

    # --- Historical CredentialList mappings ---
    def list_credential_list_mappings(domain_sid, **kwargs)
      SipCredentialListMappingList.new(@transport.request(:get, path('SIP', 'Domains', domain_sid, 'CredentialListMappings'), params: form_params(PAGE_FIELDS, kwargs)))
    end
    def create_credential_list_mapping(domain_sid, credential_list_sid:)
      SipDomainMapping.from_hash(@transport.request(:post, path('SIP', 'Domains', domain_sid, 'CredentialListMappings'), form: { 'CredentialListSid' => credential_list_sid }))
    end
    def fetch_credential_list_mapping(domain_sid, mapping_sid)
      SipDomainMapping.from_hash(@transport.request(:get, path('SIP', 'Domains', domain_sid, 'CredentialListMappings', mapping_sid)))
    end
    def delete_credential_list_mapping(domain_sid, mapping_sid)
      @transport.request(:delete, path('SIP', 'Domains', domain_sid, 'CredentialListMappings', mapping_sid)); nil
    end

    # --- Historical IpAccessControlList mappings ---
    def list_ip_access_control_list_mappings(domain_sid, **kwargs)
      SipIpAccessControlListMappingList.new(@transport.request(:get, path('SIP', 'Domains', domain_sid, 'IpAccessControlListMappings'), params: form_params(PAGE_FIELDS, kwargs)))
    end
    def create_ip_access_control_list_mapping(domain_sid, ip_access_control_list_sid:)
      SipDomainMapping.from_hash(@transport.request(:post, path('SIP', 'Domains', domain_sid, 'IpAccessControlListMappings'), form: { 'IpAccessControlListSid' => ip_access_control_list_sid }))
    end
    def fetch_ip_access_control_list_mapping(domain_sid, mapping_sid)
      SipDomainMapping.from_hash(@transport.request(:get, path('SIP', 'Domains', domain_sid, 'IpAccessControlListMappings', mapping_sid)))
    end
    def delete_ip_access_control_list_mapping(domain_sid, mapping_sid)
      @transport.request(:delete, path('SIP', 'Domains', domain_sid, 'IpAccessControlListMappings', mapping_sid)); nil
    end

    # --- Auth/Calls/CredentialListMappings ---
    def list_auth_calls_credential_list_mappings(domain_sid, **kwargs)
      SipCredentialListMappingList.new(@transport.request(:get, path('SIP', 'Domains', domain_sid, 'Auth', 'Calls', 'CredentialListMappings'), params: form_params(PAGE_FIELDS, kwargs)))
    end
    def create_auth_calls_credential_list_mapping(domain_sid, credential_list_sid:)
      SipDomainMapping.from_hash(@transport.request(:post, path('SIP', 'Domains', domain_sid, 'Auth', 'Calls', 'CredentialListMappings'), form: { 'CredentialListSid' => credential_list_sid }))
    end
    def fetch_auth_calls_credential_list_mapping(domain_sid, mapping_sid)
      SipDomainMapping.from_hash(@transport.request(:get, path('SIP', 'Domains', domain_sid, 'Auth', 'Calls', 'CredentialListMappings', mapping_sid)))
    end
    def delete_auth_calls_credential_list_mapping(domain_sid, mapping_sid)
      @transport.request(:delete, path('SIP', 'Domains', domain_sid, 'Auth', 'Calls', 'CredentialListMappings', mapping_sid)); nil
    end

    # --- Auth/Calls/IpAccessControlListMappings ---
    def list_auth_calls_ip_access_control_list_mappings(domain_sid, **kwargs)
      SipIpAccessControlListMappingList.new(@transport.request(:get, path('SIP', 'Domains', domain_sid, 'Auth', 'Calls', 'IpAccessControlListMappings'), params: form_params(PAGE_FIELDS, kwargs)))
    end
    def create_auth_calls_ip_access_control_list_mapping(domain_sid, ip_access_control_list_sid:)
      SipDomainMapping.from_hash(@transport.request(:post, path('SIP', 'Domains', domain_sid, 'Auth', 'Calls', 'IpAccessControlListMappings'), form: { 'IpAccessControlListSid' => ip_access_control_list_sid }))
    end
    def fetch_auth_calls_ip_access_control_list_mapping(domain_sid, mapping_sid)
      SipDomainMapping.from_hash(@transport.request(:get, path('SIP', 'Domains', domain_sid, 'Auth', 'Calls', 'IpAccessControlListMappings', mapping_sid)))
    end
    def delete_auth_calls_ip_access_control_list_mapping(domain_sid, mapping_sid)
      @transport.request(:delete, path('SIP', 'Domains', domain_sid, 'Auth', 'Calls', 'IpAccessControlListMappings', mapping_sid)); nil
    end

    # --- Auth/Registrations/CredentialListMappings ---
    def list_auth_registrations_credential_list_mappings(domain_sid, **kwargs)
      SipCredentialListMappingList.new(@transport.request(:get, path('SIP', 'Domains', domain_sid, 'Auth', 'Registrations', 'CredentialListMappings'), params: form_params(PAGE_FIELDS, kwargs)))
    end
    def create_auth_registrations_credential_list_mapping(domain_sid, credential_list_sid:)
      SipDomainMapping.from_hash(@transport.request(:post, path('SIP', 'Domains', domain_sid, 'Auth', 'Registrations', 'CredentialListMappings'), form: { 'CredentialListSid' => credential_list_sid }))
    end
    def fetch_auth_registrations_credential_list_mapping(domain_sid, mapping_sid)
      SipDomainMapping.from_hash(@transport.request(:get, path('SIP', 'Domains', domain_sid, 'Auth', 'Registrations', 'CredentialListMappings', mapping_sid)))
    end
    def delete_auth_registrations_credential_list_mapping(domain_sid, mapping_sid)
      @transport.request(:delete, path('SIP', 'Domains', domain_sid, 'Auth', 'Registrations', 'CredentialListMappings', mapping_sid)); nil
    end
  end

  # /SIP/CredentialLists + /Credentials sub-resource.
  class SipCredentialListsResource < BaseResource
    PAGE_FIELDS = { 'Page' => :page, 'PageSize' => :page_size, 'PageToken' => :page_token }.freeze

    def list(**kwargs)
      SipCredentialListList.new(@transport.request(:get, path('SIP', 'CredentialLists'), params: form_params(PAGE_FIELDS, kwargs)))
    end
    def create(friendly_name:)
      SipCredentialList.from_hash(@transport.request(:post, path('SIP', 'CredentialLists'), form: { 'FriendlyName' => friendly_name }))
    end
    def fetch(credential_list_sid)
      SipCredentialList.from_hash(@transport.request(:get, path('SIP', 'CredentialLists', credential_list_sid)))
    end
    def update(credential_list_sid, friendly_name: nil)
      form = friendly_name.nil? ? {} : { 'FriendlyName' => friendly_name }
      SipCredentialList.from_hash(@transport.request(:post, path('SIP', 'CredentialLists', credential_list_sid), form: form))
    end
    def delete(credential_list_sid)
      @transport.request(:delete, path('SIP', 'CredentialLists', credential_list_sid)); nil
    end

    # /Credentials sub-resource
    def list_credentials(credential_list_sid, **kwargs)
      SipCredentialListPage.new(@transport.request(:get, path('SIP', 'CredentialLists', credential_list_sid, 'Credentials'), params: form_params(PAGE_FIELDS, kwargs)))
    end
    def create_credential(credential_list_sid, username:, password:)
      SipCredential.from_hash(@transport.request(:post, path('SIP', 'CredentialLists', credential_list_sid, 'Credentials'), form: { 'Username' => username, 'Password' => password }))
    end
    def fetch_credential(credential_list_sid, credential_sid)
      SipCredential.from_hash(@transport.request(:get, path('SIP', 'CredentialLists', credential_list_sid, 'Credentials', credential_sid)))
    end
    def update_credential(credential_list_sid, credential_sid, password:)
      SipCredential.from_hash(@transport.request(:post, path('SIP', 'CredentialLists', credential_list_sid, 'Credentials', credential_sid), form: { 'Password' => password }))
    end
    def delete_credential(credential_list_sid, credential_sid)
      @transport.request(:delete, path('SIP', 'CredentialLists', credential_list_sid, 'Credentials', credential_sid)); nil
    end
  end

  # /SIP/IpAccessControlLists + /IpAddresses sub-resource.
  class SipIpAccessControlListsResource < BaseResource
    PAGE_FIELDS = { 'Page' => :page, 'PageSize' => :page_size, 'PageToken' => :page_token }.freeze
    IP_FIELDS = { 'FriendlyName' => :friendly_name, 'IpAddress' => :ip_address, 'CidrPrefixLength' => :cidr_prefix_length }.freeze

    def list(**kwargs)
      SipIpAccessControlListList.new(@transport.request(:get, path('SIP', 'IpAccessControlLists'), params: form_params(PAGE_FIELDS, kwargs)))
    end
    def create(friendly_name:)
      SipIpAccessControlList.from_hash(@transport.request(:post, path('SIP', 'IpAccessControlLists'), form: { 'FriendlyName' => friendly_name }))
    end
    def fetch(acl_sid)
      SipIpAccessControlList.from_hash(@transport.request(:get, path('SIP', 'IpAccessControlLists', acl_sid)))
    end
    def update(acl_sid, friendly_name: nil)
      form = friendly_name.nil? ? {} : { 'FriendlyName' => friendly_name }
      SipIpAccessControlList.from_hash(@transport.request(:post, path('SIP', 'IpAccessControlLists', acl_sid), form: form))
    end
    def delete(acl_sid)
      @transport.request(:delete, path('SIP', 'IpAccessControlLists', acl_sid)); nil
    end

    # /IpAddresses sub-resource
    def list_ip_addresses(acl_sid, **kwargs)
      SipIpAddressList.new(@transport.request(:get, path('SIP', 'IpAccessControlLists', acl_sid, 'IpAddresses'), params: form_params(PAGE_FIELDS, kwargs)))
    end
    def create_ip_address(acl_sid, friendly_name:, ip_address:, cidr_prefix_length: nil)
      form = { 'FriendlyName' => friendly_name, 'IpAddress' => ip_address }
      form['CidrPrefixLength'] = cidr_prefix_length unless cidr_prefix_length.nil?
      SipIpAddress.from_hash(@transport.request(:post, path('SIP', 'IpAccessControlLists', acl_sid, 'IpAddresses'), form: form))
    end
    def fetch_ip_address(acl_sid, ip_address_sid)
      SipIpAddress.from_hash(@transport.request(:get, path('SIP', 'IpAccessControlLists', acl_sid, 'IpAddresses', ip_address_sid)))
    end
    def update_ip_address(acl_sid, ip_address_sid, **kwargs)
      SipIpAddress.from_hash(@transport.request(:post, path('SIP', 'IpAccessControlLists', acl_sid, 'IpAddresses', ip_address_sid), form: form_params(IP_FIELDS, kwargs)))
    end
    def delete_ip_address(acl_sid, ip_address_sid)
      @transport.request(:delete, path('SIP', 'IpAccessControlLists', acl_sid, 'IpAddresses', ip_address_sid)); nil
    end
  end
end
