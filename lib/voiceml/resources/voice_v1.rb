# frozen_string_literal: true

require_relative '../models/voice_v1'

module VoiceML
  # `client.voice_v1` — Twilio Voice v1 (voice.twilio.com/v1) surface.
  # Sits outside the /2010-04-01/Accounts/... namespace; account resolved from Basic auth.
  class VoiceV1Resource
    attr_reader :ip_records, :source_ip_mappings, :byoc_trunks,
                :connection_policies, :dialing_permissions

    def initialize(transport)
      @ip_records          = VoiceV1IpRecordsResource.new(transport)
      @source_ip_mappings  = VoiceV1SourceIpMappingsResource.new(transport)
      @byoc_trunks         = VoiceV1ByocTrunksResource.new(transport)
      @connection_policies = VoiceV1ConnectionPoliciesResource.new(transport)
      @dialing_permissions = VoiceV1DialingPermissionsResource.new(transport)
    end
  end

  # /v1/IpRecords + /v1/IpRecords/{Sid}
  class VoiceV1IpRecordsResource
    def initialize(transport)
      @transport = transport
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      VoiceV1IpRecordList.new(@transport.request(:get, '/v1/IpRecords', params: params))
    end

    def create(ip_address:, friendly_name: nil, cidr_prefix_length: nil)
      form = { 'IpAddress' => ip_address }
      form['FriendlyName']     = friendly_name unless friendly_name.nil?
      form['CidrPrefixLength'] = cidr_prefix_length unless cidr_prefix_length.nil?
      VoiceV1IpRecord.from_hash(@transport.request(:post, '/v1/IpRecords', form: form))
    end

    def fetch(sid)
      VoiceV1IpRecord.from_hash(@transport.request(:get, "/v1/IpRecords/#{sid}"))
    end

    def update(sid, friendly_name: nil)
      form = {}
      form['FriendlyName'] = friendly_name unless friendly_name.nil?
      VoiceV1IpRecord.from_hash(@transport.request(:post, "/v1/IpRecords/#{sid}", form: form))
    end

    def delete(sid)
      @transport.request(:delete, "/v1/IpRecords/#{sid}")
      nil
    end
  end

  # /v1/SourceIpMappings + /v1/SourceIpMappings/{Sid}
  class VoiceV1SourceIpMappingsResource
    def initialize(transport)
      @transport = transport
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      VoiceV1SourceIpMappingList.new(@transport.request(:get, '/v1/SourceIpMappings', params: params))
    end

    def create(ip_record_sid:, sip_domain_sid:)
      form = { 'IpRecordSid' => ip_record_sid, 'SipDomainSid' => sip_domain_sid }
      VoiceV1SourceIpMapping.from_hash(@transport.request(:post, '/v1/SourceIpMappings', form: form))
    end

    def fetch(sid)
      VoiceV1SourceIpMapping.from_hash(@transport.request(:get, "/v1/SourceIpMappings/#{sid}"))
    end

    def update(sid, sip_domain_sid:)
      form = { 'SipDomainSid' => sip_domain_sid }
      VoiceV1SourceIpMapping.from_hash(@transport.request(:post, "/v1/SourceIpMappings/#{sid}", form: form))
    end

    def delete(sid)
      @transport.request(:delete, "/v1/SourceIpMappings/#{sid}")
      nil
    end
  end

  # /v1/ByocTrunks + /v1/ByocTrunks/{Sid}
  class VoiceV1ByocTrunksResource
    TRUNK_FIELDS = {
      'FriendlyName' => :friendly_name,
      'VoiceUrl' => :voice_url,
      'VoiceMethod' => :voice_method,
      'VoiceFallbackUrl' => :voice_fallback_url,
      'VoiceFallbackMethod' => :voice_fallback_method,
      'StatusCallbackUrl' => :status_callback_url,
      'StatusCallbackMethod' => :status_callback_method,
      'CnamLookupEnabled' => :cnam_lookup_enabled,
      'ConnectionPolicySid' => :connection_policy_sid,
      'FromDomainSid' => :from_domain_sid
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      VoiceV1ByocTrunkList.new(@transport.request(:get, '/v1/ByocTrunks', params: params))
    end

    def create(**kwargs)
      VoiceV1ByocTrunk.from_hash(@transport.request(:post, '/v1/ByocTrunks', form: build_form(kwargs)))
    end

    def fetch(sid)
      VoiceV1ByocTrunk.from_hash(@transport.request(:get, "/v1/ByocTrunks/#{sid}"))
    end

    def update(sid, **kwargs)
      VoiceV1ByocTrunk.from_hash(@transport.request(:post, "/v1/ByocTrunks/#{sid}", form: build_form(kwargs)))
    end

    def delete(sid)
      @transport.request(:delete, "/v1/ByocTrunks/#{sid}")
      nil
    end

    private

    def build_form(kwargs)
      out = {}
      TRUNK_FIELDS.each do |wire, k|
        value = kwargs[k]
        next if value.nil?

        out[wire] = value
      end
      out
    end
  end

  # /v1/ConnectionPolicies + /v1/ConnectionPolicies/{Sid} + nested /Targets
  class VoiceV1ConnectionPoliciesResource
    TARGET_FIELDS = {
      'Target' => :target,
      'FriendlyName' => :friendly_name,
      'Priority' => :priority,
      'Weight' => :weight,
      'Enabled' => :enabled
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      VoiceV1ConnectionPolicyList.new(@transport.request(:get, '/v1/ConnectionPolicies', params: params))
    end

    def create(friendly_name: nil)
      form = {}
      form['FriendlyName'] = friendly_name unless friendly_name.nil?
      VoiceV1ConnectionPolicy.from_hash(@transport.request(:post, '/v1/ConnectionPolicies', form: form))
    end

    def fetch(sid)
      VoiceV1ConnectionPolicy.from_hash(@transport.request(:get, "/v1/ConnectionPolicies/#{sid}"))
    end

    def update(sid, friendly_name: nil)
      form = {}
      form['FriendlyName'] = friendly_name unless friendly_name.nil?
      VoiceV1ConnectionPolicy.from_hash(@transport.request(:post, "/v1/ConnectionPolicies/#{sid}", form: form))
    end

    def delete(sid)
      @transport.request(:delete, "/v1/ConnectionPolicies/#{sid}")
      nil
    end

    # --- /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets ---
    def list_targets(connection_policy_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      VoiceV1ConnectionPolicyTargetList.new(
        @transport.request(:get, "/v1/ConnectionPolicies/#{connection_policy_sid}/Targets", params: params)
      )
    end

    def create_target(connection_policy_sid, target:, friendly_name: nil, priority: nil, weight: nil, enabled: nil)
      kwargs = { target: target, friendly_name: friendly_name, priority: priority, weight: weight, enabled: enabled }
      VoiceV1ConnectionPolicyTarget.from_hash(
        @transport.request(:post, "/v1/ConnectionPolicies/#{connection_policy_sid}/Targets",
                           form: build_target_form(kwargs))
      )
    end

    def fetch_target(connection_policy_sid, sid)
      VoiceV1ConnectionPolicyTarget.from_hash(
        @transport.request(:get, "/v1/ConnectionPolicies/#{connection_policy_sid}/Targets/#{sid}")
      )
    end

    def update_target(connection_policy_sid, sid, **kwargs)
      VoiceV1ConnectionPolicyTarget.from_hash(
        @transport.request(:post, "/v1/ConnectionPolicies/#{connection_policy_sid}/Targets/#{sid}",
                           form: build_target_form(kwargs))
      )
    end

    def delete_target(connection_policy_sid, sid)
      @transport.request(:delete, "/v1/ConnectionPolicies/#{connection_policy_sid}/Targets/#{sid}")
      nil
    end

    private

    def build_target_form(kwargs)
      out = {}
      TARGET_FIELDS.each do |wire, k|
        value = kwargs[k]
        next if value.nil?

        out[wire] = value
      end
      out
    end
  end

  # /v1/Settings — DialingPermissions inheritance toggle (singleton).
  class VoiceV1DialingPermissionsResource
    def initialize(transport)
      @transport = transport
    end

    def fetch_settings
      VoiceV1DialingPermissionsSettings.from_hash(@transport.request(:get, '/v1/Settings'))
    end

    def update_settings(dialing_permissions_inheritance: nil)
      form = {}
      form['DialingPermissionsInheritance'] = dialing_permissions_inheritance unless dialing_permissions_inheritance.nil?
      VoiceV1DialingPermissionsSettings.from_hash(@transport.request(:post, '/v1/Settings', form: form))
    end
  end
end
