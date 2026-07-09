# frozen_string_literal: true

require 'spec_helper'

# Wire-shape tests for the v0.9.0 surface (#420 Voice v1 + #421 Conversations v1 +
# Routes V2 PhoneNumber). Verifies that the new namespaces are wired on the
# client, that paths/methods match the spec, and that snake_case kwargs map to
# the PascalCase wire field names the server expects.
RSpec.describe 'VoiceML v0.9.0 — Voice v1, Conversations v1, Routes V2 PhoneNumber' do
  let(:account_sid) { 'AC' + ('a' * 32) }
  let(:api_key)     { 'secret-key-9000' }
  let(:client)      { VoiceML::Client.new(account_sid: account_sid, api_key: api_key, base_url: base_url) }
  let(:base_url)    { 'https://voiceml.example.test' }

  let(:il_sid) { 'IL' + ('1' * 32) }
  let(:ib_sid) { 'IB' + ('2' * 32) }
  let(:by_sid) { 'BY' + ('3' * 32) }
  let(:ny_sid) { 'NY' + ('4' * 32) }
  let(:ne_sid) { 'NE' + ('5' * 32) }
  let(:sd_sid) { 'SD' + ('6' * 32) }

  let(:ch_sid) { 'CH' + ('7' * 32) }
  let(:im_sid) { 'IM' + ('8' * 32) }
  let(:mb_sid) { 'MB' + ('9' * 32) }
  let(:dy_sid) { 'DY' + ('a' * 32) }
  let(:wh_sid) { 'WH' + ('b' * 32) }
  let(:rl_sid) { 'RL' + ('c' * 32) }
  let(:us_sid) { 'US' + ('d' * 32) }
  let(:cr_sid) { 'CR' + ('e' * 32) }
  let(:ig_sid) { 'IG' + ('f' * 32) }
  let(:is_sid) { 'IS' + ('0' * 32) }
  let(:qq_sid) { 'QQ' + ('1' * 32) }

  let(:phone_number) { '+18005551234' }

  def meta(url: nil)
    { first_page_url: url, next_page_url: nil, previous_page_url: nil,
      url: url, page: 0, page_size: 50, key: 'items' }
  end

  describe 'VoiceML::VERSION' do
    it 'reports 0.9.2' do
      expect(VoiceML::VERSION).to eq('0.9.2')
    end
  end

  describe 'client wiring' do
    it 'exposes voice_v1 + conversations_v1 + routes_v2.phone_numbers' do
      expect(client.voice_v1).to be_a(VoiceML::VoiceV1Resource)
      expect(client.voice_v1.ip_records).to be_a(VoiceML::VoiceV1IpRecordsResource)
      expect(client.voice_v1.source_ip_mappings).to be_a(VoiceML::VoiceV1SourceIpMappingsResource)
      expect(client.voice_v1.byoc_trunks).to be_a(VoiceML::VoiceV1ByocTrunksResource)
      expect(client.voice_v1.connection_policies).to be_a(VoiceML::VoiceV1ConnectionPoliciesResource)
      expect(client.voice_v1.dialing_permissions).to be_a(VoiceML::VoiceV1DialingPermissionsResource)

      expect(client.conversations_v1).to be_a(VoiceML::ConversationsV1Resource)
      expect(client.conversations_v1.conversations).to be_a(VoiceML::ConversationsV1ConversationsResource)
      expect(client.conversations_v1.roles).to be_a(VoiceML::ConversationsV1RolesResource)
      expect(client.conversations_v1.users).to be_a(VoiceML::ConversationsV1UsersResource)
      expect(client.conversations_v1.credentials).to be_a(VoiceML::ConversationsV1CredentialsResource)
      expect(client.conversations_v1.configuration).to be_a(VoiceML::ConversationsV1ConfigurationResource)
      expect(client.conversations_v1.participant_conversations).to be_a(VoiceML::ConversationsV1ParticipantConversationsResource)
      expect(client.conversations_v1.conversation_with_participants).to be_a(VoiceML::ConversationsV1ConversationWithParticipantsResource)
      expect(client.conversations_v1.services).to be_a(VoiceML::ConversationsV1ServicesResource)

      expect(client.routes_v2.phone_numbers).to be_a(VoiceML::RoutesV2PhoneNumbersResource)
    end
  end

  # ===========================================================================
  # Voice v1
  # ===========================================================================
  describe 'Voice v1 IpRecords' do
    let(:body) do
      { sid: il_sid, account_sid: account_sid, friendly_name: 'carrier-a',
        ip_address: '203.0.113.10', cidr_prefix_length: 32,
        date_created: '2026-06-27T12:00:00Z', date_updated: '2026-06-27T12:00:00Z',
        url: "#{base_url}/v1/IpRecords/#{il_sid}" }.to_json
    end

    it 'create POSTs IpAddress + FriendlyName + CidrPrefixLength' do
      stub_request(:post, "#{base_url}/v1/IpRecords")
        .with(body: hash_including('IpAddress' => '203.0.113.10',
                                    'FriendlyName' => 'carrier-a',
                                    'CidrPrefixLength' => '32'))
        .to_return(status: 201, body: body, headers: { 'Content-Type' => 'application/json' })
      rec = client.voice_v1.ip_records.create(ip_address: '203.0.113.10',
                                              friendly_name: 'carrier-a',
                                              cidr_prefix_length: 32)
      expect(rec.sid).to eq(il_sid)
      expect(rec.cidr_prefix_length).to eq(32)
    end

    it 'list returns meta envelope + ip_records' do
      payload = { ip_records: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/IpRecords?PageSize=50") }.to_json
      stub_request(:get, "#{base_url}/v1/IpRecords")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = client.voice_v1.ip_records.list
      expect(page.ip_records.length).to eq(1)
      expect(page.ip_records.first.sid).to eq(il_sid)
      expect(page.page).to eq(0)
      expect(page.page_size).to eq(50)
    end

    it 'fetch + update + delete' do
      stub_request(:get, "#{base_url}/v1/IpRecords/#{il_sid}")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}/v1/IpRecords/#{il_sid}")
        .with(body: hash_including('FriendlyName' => 'renamed'))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/IpRecords/#{il_sid}").to_return(status: 204)

      expect(client.voice_v1.ip_records.fetch(il_sid).sid).to eq(il_sid)
      expect(client.voice_v1.ip_records.update(il_sid, friendly_name: 'renamed').sid).to eq(il_sid)
      expect(client.voice_v1.ip_records.delete(il_sid)).to be_nil
    end
  end

  describe 'Voice v1 SourceIpMappings' do
    let(:body) do
      { sid: ib_sid, ip_record_sid: il_sid, sip_domain_sid: sd_sid,
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create requires IpRecordSid + SipDomainSid' do
      stub_request(:post, "#{base_url}/v1/SourceIpMappings")
        .with(body: hash_including('IpRecordSid' => il_sid, 'SipDomainSid' => sd_sid))
        .to_return(status: 201, body: body, headers: { 'Content-Type' => 'application/json' })
      m = client.voice_v1.source_ip_mappings.create(ip_record_sid: il_sid, sip_domain_sid: sd_sid)
      expect(m.sid).to eq(ib_sid)
    end

    it 'update sends only SipDomainSid' do
      stub_request(:post, "#{base_url}/v1/SourceIpMappings/#{ib_sid}")
        .with(body: { 'SipDomainSid' => sd_sid })
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      client.voice_v1.source_ip_mappings.update(ib_sid, sip_domain_sid: sd_sid)
    end
  end

  describe 'Voice v1 ByocTrunks' do
    let(:body) do
      { sid: by_sid, account_sid: account_sid, friendly_name: 'carrier-x',
        voice_url: 'https://hooks/voice', voice_method: 'POST',
        connection_policy_sid: ny_sid, from_domain_sid: sd_sid,
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create maps snake_case to PascalCase wire fields' do
      stub_request(:post, "#{base_url}/v1/ByocTrunks")
        .with(body: hash_including('FriendlyName' => 'carrier-x',
                                    'VoiceUrl' => 'https://hooks/voice',
                                    'VoiceMethod' => 'POST',
                                    'ConnectionPolicySid' => ny_sid,
                                    'FromDomainSid' => sd_sid,
                                    'CnamLookupEnabled' => 'true'))
        .to_return(status: 201, body: body, headers: { 'Content-Type' => 'application/json' })
      t = client.voice_v1.byoc_trunks.create(friendly_name: 'carrier-x',
                                              voice_url: 'https://hooks/voice',
                                              voice_method: 'POST',
                                              connection_policy_sid: ny_sid,
                                              from_domain_sid: sd_sid,
                                              cnam_lookup_enabled: true)
      expect(t.sid).to eq(by_sid)
    end
  end

  describe 'Voice v1 ConnectionPolicies + Targets' do
    let(:cp_body) do
      { sid: ny_sid, account_sid: account_sid, friendly_name: 'origination-policy',
        date_created: 'x', date_updated: 'x', url: 'x', links: { targets: 'x' } }.to_json
    end
    let(:target_body) do
      { sid: ne_sid, account_sid: account_sid, connection_policy_sid: ny_sid,
        target: 'sip:edge@example.com', priority: 10, weight: 5, enabled: true,
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create policy POSTs FriendlyName' do
      stub_request(:post, "#{base_url}/v1/ConnectionPolicies")
        .with(body: hash_including('FriendlyName' => 'origination-policy'))
        .to_return(status: 201, body: cp_body, headers: { 'Content-Type' => 'application/json' })
      p = client.voice_v1.connection_policies.create(friendly_name: 'origination-policy')
      expect(p.sid).to eq(ny_sid)
    end

    it 'create_target POSTs to /Targets with Target/Priority/Weight/Enabled' do
      stub_request(:post, "#{base_url}/v1/ConnectionPolicies/#{ny_sid}/Targets")
        .with(body: hash_including('Target' => 'sip:edge@example.com',
                                    'Priority' => '10', 'Weight' => '5',
                                    'Enabled' => 'true'))
        .to_return(status: 201, body: target_body, headers: { 'Content-Type' => 'application/json' })
      t = client.voice_v1.connection_policies.create_target(ny_sid,
            target: 'sip:edge@example.com', priority: 10, weight: 5, enabled: true)
      expect(t.sid).to eq(ne_sid)
      expect(t.priority).to eq(10)
    end

    it 'list_targets returns targets array' do
      payload = { targets: [JSON.parse(target_body)],
                  meta: meta(url: "#{base_url}/v1/ConnectionPolicies/#{ny_sid}/Targets") }.to_json
      stub_request(:get, "#{base_url}/v1/ConnectionPolicies/#{ny_sid}/Targets")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = client.voice_v1.connection_policies.list_targets(ny_sid)
      expect(page.targets.length).to eq(1)
      expect(page.targets.first.sid).to eq(ne_sid)
    end
  end

  describe 'Voice v1 DialingPermissions Settings' do
    let(:settings_body) do
      { dialing_permissions_inheritance: true, url: "#{base_url}/v1/Settings" }.to_json
    end

    it 'fetch GETs /v1/Settings' do
      stub_request(:get, "#{base_url}/v1/Settings")
        .to_return(status: 200, body: settings_body, headers: { 'Content-Type' => 'application/json' })
      s = client.voice_v1.dialing_permissions.fetch_settings
      expect(s.dialing_permissions_inheritance).to be true
    end

    it 'update POSTs DialingPermissionsInheritance' do
      stub_request(:post, "#{base_url}/v1/Settings")
        .with(body: hash_including('DialingPermissionsInheritance' => 'false'))
        .to_return(status: 202, body: settings_body, headers: { 'Content-Type' => 'application/json' })
      client.voice_v1.dialing_permissions.update_settings(dialing_permissions_inheritance: false)
    end
  end

  # ===========================================================================
  # Conversations v1
  # ===========================================================================
  describe 'Conversations v1 Conversations' do
    let(:conv_body) do
      { sid: ch_sid, account_sid: account_sid, state: 'active', attributes: '{}',
        friendly_name: 'Support thread', unique_name: 'support-1',
        date_created: '2026-06-27T12:00:00Z', date_updated: '2026-06-27T12:00:00Z',
        url: "#{base_url}/v1/Conversations/#{ch_sid}" }.to_json
    end

    it 'create POSTs FriendlyName / UniqueName / State / Attributes / Timers.* / Bindings.*' do
      stub_request(:post, "#{base_url}/v1/Conversations")
        .with(body: hash_including(
          'FriendlyName' => 'Support thread',
          'UniqueName'   => 'support-1',
          'State'        => 'active',
          'Attributes'   => '{"priority":"high"}',
          'Timers.Inactive' => 'PT1H',
          'Timers.Closed'   => 'PT24H',
          'Bindings.Email.Address' => 'support@example.com',
          'Bindings.Email.Name'    => 'Support'
        ))
        .to_return(status: 201, body: conv_body, headers: { 'Content-Type' => 'application/json' })
      c = client.conversations_v1.conversations.create(
        friendly_name: 'Support thread', unique_name: 'support-1',
        state: 'active', attributes: '{"priority":"high"}',
        timers_inactive: 'PT1H', timers_closed: 'PT24H',
        bindings_email_address: 'support@example.com',
        bindings_email_name: 'Support'
      )
      expect(c.sid).to eq(ch_sid)
      expect(c.state).to eq('active')
    end

    it 'list returns the meta envelope + conversations array' do
      payload = { conversations: [JSON.parse(conv_body)],
                  meta: meta(url: "#{base_url}/v1/Conversations") }.to_json
      stub_request(:get, "#{base_url}/v1/Conversations")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = client.conversations_v1.conversations.list
      expect(page.conversations.first.sid).to eq(ch_sid)
    end

    it 'fetch, update, delete' do
      stub_request(:get, "#{base_url}/v1/Conversations/#{ch_sid}")
        .to_return(status: 200, body: conv_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}/v1/Conversations/#{ch_sid}")
        .with(body: hash_including('State' => 'closed'))
        .to_return(status: 200, body: conv_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Conversations/#{ch_sid}").to_return(status: 204)

      expect(client.conversations_v1.conversations.fetch(ch_sid).sid).to eq(ch_sid)
      expect(client.conversations_v1.conversations.update(ch_sid, state: 'closed').sid).to eq(ch_sid)
      expect(client.conversations_v1.conversations.delete(ch_sid)).to be_nil
    end
  end

  describe 'Conversations v1 Messages + Participants + Webhooks + Receipts' do
    let(:msg_body) do
      { sid: im_sid, account_sid: account_sid, conversation_sid: ch_sid,
        index: 0, author: '+15551234567', body: 'Hello', attributes: '{}',
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end
    let(:participant_body) do
      { sid: mb_sid, account_sid: account_sid, conversation_sid: ch_sid,
        identity: 'alice', attributes: '{}',
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end
    let(:webhook_body) do
      { sid: wh_sid, account_sid: account_sid, conversation_sid: ch_sid,
        target: 'webhook', url: 'x', configuration: { 'url' => 'https://example.com/hook' },
        date_created: 'x', date_updated: 'x' }.to_json
    end
    let(:receipt_body) do
      { sid: dy_sid, account_sid: account_sid, conversation_sid: ch_sid,
        message_sid: im_sid, status: 'delivered', error_code: 0,
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create_message POSTs Author + Body + Attributes' do
      stub_request(:post, "#{base_url}/v1/Conversations/#{ch_sid}/Messages")
        .with(body: hash_including('Author' => '+15551234567', 'Body' => 'Hello'))
        .to_return(status: 201, body: msg_body, headers: { 'Content-Type' => 'application/json' })
      m = client.conversations_v1.conversations.create_message(ch_sid,
            author: '+15551234567', body: 'Hello')
      expect(m.sid).to eq(im_sid)
      expect(m.index).to eq(0)
    end

    it 'create_participant POSTs MessagingBinding.Address' do
      stub_request(:post, "#{base_url}/v1/Conversations/#{ch_sid}/Participants")
        .with(body: hash_including('Identity' => 'alice',
                                    'MessagingBinding.Address' => '+18005550000'))
        .to_return(status: 201, body: participant_body, headers: { 'Content-Type' => 'application/json' })
      p = client.conversations_v1.conversations.create_participant(ch_sid,
            identity: 'alice', messaging_binding_address: '+18005550000')
      expect(p.sid).to eq(mb_sid)
    end

    it 'create_webhook POSTs Target + Configuration.Url' do
      stub_request(:post, "#{base_url}/v1/Conversations/#{ch_sid}/Webhooks")
        .with(body: hash_including('Target' => 'webhook',
                                    'Configuration.Url' => 'https://example.com/hook',
                                    'Configuration.Method' => 'POST'))
        .to_return(status: 201, body: webhook_body, headers: { 'Content-Type' => 'application/json' })
      w = client.conversations_v1.conversations.create_webhook(ch_sid,
            target: 'webhook',
            configuration_url: 'https://example.com/hook',
            configuration_method: 'POST')
      expect(w.sid).to eq(wh_sid)
    end

    it 'list_message_receipts returns delivery_receipts array' do
      payload = { delivery_receipts: [JSON.parse(receipt_body)],
                  meta: meta(url: "#{base_url}/v1/Conversations/#{ch_sid}/Messages/#{im_sid}/Receipts") }.to_json
      stub_request(:get, "#{base_url}/v1/Conversations/#{ch_sid}/Messages/#{im_sid}/Receipts")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = client.conversations_v1.conversations.list_message_receipts(ch_sid, im_sid)
      expect(page.delivery_receipts.first.sid).to eq(dy_sid)
      expect(page.delivery_receipts.first.status).to eq('delivered')
    end
  end

  describe 'Conversations v1 Roles' do
    let(:role_body) do
      { sid: rl_sid, account_sid: account_sid, type: 'conversation',
        friendly_name: 'admin', permissions: %w[addParticipant editConversationName],
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create POSTs FriendlyName + Type + repeated Permission' do
      stub_request(:post, "#{base_url}/v1/Roles")
        .with { |req| req.body.include?('FriendlyName=admin') &&
                       req.body.include?('Type=conversation') &&
                       req.body.scan('Permission=').length == 2 }
        .to_return(status: 201, body: role_body, headers: { 'Content-Type' => 'application/json' })
      r = client.conversations_v1.roles.create(
        friendly_name: 'admin', type: 'conversation',
        permission: %w[addParticipant editConversationName]
      )
      expect(r.sid).to eq(rl_sid)
    end
  end

  describe 'Conversations v1 Users + UserConversations' do
    let(:user_body) do
      { sid: us_sid, account_sid: account_sid, identity: 'alice',
        friendly_name: 'Alice', attributes: '{}', is_online: true, is_notifiable: false,
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end
    let(:uc_body) do
      { account_sid: account_sid, conversation_sid: ch_sid, user_sid: us_sid,
        conversation_state: 'active', notification_level: 'muted',
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create POSTs Identity + FriendlyName + RoleSid' do
      stub_request(:post, "#{base_url}/v1/Users")
        .with(body: hash_including('Identity' => 'alice',
                                    'FriendlyName' => 'Alice',
                                    'RoleSid' => rl_sid))
        .to_return(status: 201, body: user_body, headers: { 'Content-Type' => 'application/json' })
      u = client.conversations_v1.users.create(identity: 'alice', friendly_name: 'Alice', role_sid: rl_sid)
      expect(u.sid).to eq(us_sid)
    end

    it 'update_user_conversation POSTs NotificationLevel' do
      stub_request(:post, "#{base_url}/v1/Users/#{us_sid}/Conversations/#{ch_sid}")
        .with(body: hash_including('NotificationLevel' => 'muted'))
        .to_return(status: 200, body: uc_body, headers: { 'Content-Type' => 'application/json' })
      uc = client.conversations_v1.users.update_user_conversation(us_sid, ch_sid, notification_level: 'muted')
      expect(uc.notification_level).to eq('muted')
    end
  end

  describe 'Conversations v1 Credentials' do
    let(:cred_body) do
      { sid: cr_sid, account_sid: account_sid, type: 'apn', friendly_name: 'ios-prod',
        sandbox: 'true', date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create POSTs Type + FriendlyName + Sandbox' do
      stub_request(:post, "#{base_url}/v1/Credentials")
        .with(body: hash_including('Type' => 'apn',
                                    'FriendlyName' => 'ios-prod',
                                    'Sandbox' => 'true'))
        .to_return(status: 201, body: cred_body, headers: { 'Content-Type' => 'application/json' })
      c = client.conversations_v1.credentials.create(type: 'apn', friendly_name: 'ios-prod', sandbox: true)
      expect(c.sid).to eq(cr_sid)
      expect(c.type).to eq('apn')
    end
  end

  describe 'Conversations v1 Configuration + Webhooks + Addresses' do
    let(:cfg_body) do
      { account_sid: account_sid, default_inactive_timer: 'PT1H',
        default_closed_timer: 'PT24H',
        url: "#{base_url}/v1/Configuration" }.to_json
    end
    let(:cfg_wh_body) do
      { account_sid: account_sid, method: 'POST', target: 'webhook',
        pre_webhook_url: 'https://example.com/pre',
        post_webhook_url: 'https://example.com/post',
        url: "#{base_url}/v1/Configuration/Webhooks" }.to_json
    end
    let(:addr_body) do
      { sid: ig_sid, account_sid: account_sid, type: 'sms', address: '+18005551234',
        friendly_name: 'Inbound SMS',
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'fetch + update Configuration singleton' do
      stub_request(:get, "#{base_url}/v1/Configuration")
        .to_return(status: 200, body: cfg_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}/v1/Configuration")
        .with(body: hash_including('DefaultInactiveTimer' => 'PT2H'))
        .to_return(status: 200, body: cfg_body, headers: { 'Content-Type' => 'application/json' })

      expect(client.conversations_v1.configuration.fetch.default_inactive_timer).to eq('PT1H')
      client.conversations_v1.configuration.update(default_inactive_timer: 'PT2H')
    end

    it 'fetch + update webhooks singleton' do
      stub_request(:get, "#{base_url}/v1/Configuration/Webhooks")
        .to_return(status: 200, body: cfg_wh_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}/v1/Configuration/Webhooks")
        .with(body: hash_including('Method' => 'POST',
                                    'PreWebhookUrl' => 'https://example.com/pre',
                                    'Target' => 'webhook'))
        .to_return(status: 200, body: cfg_wh_body, headers: { 'Content-Type' => 'application/json' })

      expect(client.conversations_v1.configuration.fetch_webhooks.target).to eq('webhook')
      client.conversations_v1.configuration.update_webhooks(method: 'POST',
                                                             pre_webhook_url: 'https://example.com/pre',
                                                             target: 'webhook')
    end

    it 'create_address POSTs Type + Address + AutoCreation.* + AddressCountry' do
      stub_request(:post, "#{base_url}/v1/Configuration/Addresses")
        .with(body: hash_including('Type' => 'sms',
                                    'Address' => '+18005551234',
                                    'FriendlyName' => 'Inbound SMS',
                                    'AutoCreation.Enabled' => 'true',
                                    'AutoCreation.Type' => 'webhook',
                                    'AutoCreation.WebhookUrl' => 'https://example.com/auto',
                                    'AddressCountry' => 'US'))
        .to_return(status: 201, body: addr_body, headers: { 'Content-Type' => 'application/json' })
      a = client.conversations_v1.configuration.create_address(
        type: 'sms', address: '+18005551234', friendly_name: 'Inbound SMS',
        auto_creation_enabled: true, auto_creation_type: 'webhook',
        auto_creation_webhook_url: 'https://example.com/auto',
        address_country: 'US'
      )
      expect(a.sid).to eq(ig_sid)
    end

    it 'list_addresses returns addresses array' do
      payload = { addresses: [JSON.parse(addr_body)],
                  meta: meta(url: "#{base_url}/v1/Configuration/Addresses") }.to_json
      stub_request(:get, "#{base_url}/v1/Configuration/Addresses")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = client.conversations_v1.configuration.list_addresses
      expect(page.addresses.first.sid).to eq(ig_sid)
    end
  end

  describe 'Conversations v1 ParticipantConversations + ConversationWithParticipants' do
    let(:pc_body) do
      { account_sid: account_sid, participant_identity: 'alice',
        conversation_sid: ch_sid, conversation_state: 'active',
        conversation_date_created: 'x', conversation_date_updated: 'x' }.to_json
    end

    it 'ParticipantConversations.list filters by Identity' do
      payload = { conversations: [JSON.parse(pc_body)],
                  meta: meta(url: "#{base_url}/v1/ParticipantConversations?Identity=alice") }.to_json
      stub_request(:get, "#{base_url}/v1/ParticipantConversations")
        .with(query: hash_including('Identity' => 'alice'))
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = client.conversations_v1.participant_conversations.list(identity: 'alice')
      expect(page.conversations.first.participant_identity).to eq('alice')
    end

    it 'ConversationWithParticipants.create POSTs repeated Participant' do
      conv = { sid: ch_sid, account_sid: account_sid, state: 'active', attributes: '{}',
               date_created: 'x', date_updated: 'x', url: 'x' }.to_json
      stub_request(:post, "#{base_url}/v1/ConversationWithParticipants")
        .with { |req| req.body.include?('FriendlyName=group-chat') &&
                       req.body.scan('Participant=').length == 2 }
        .to_return(status: 201, body: conv, headers: { 'Content-Type' => 'application/json' })
      c = client.conversations_v1.conversation_with_participants.create(
        friendly_name: 'group-chat',
        participant: ['{"identity":"alice"}', '{"identity":"bob"}']
      )
      expect(c.sid).to eq(ch_sid)
    end
  end

  describe 'Conversations v1 Services + ServiceConversations' do
    let(:svc_body) do
      { sid: is_sid, account_sid: account_sid, friendly_name: 'my-service',
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end
    let(:svc_conv_body) do
      { sid: ch_sid, account_sid: account_sid, chat_service_sid: is_sid,
        state: 'active', attributes: '{}',
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create service POSTs FriendlyName' do
      stub_request(:post, "#{base_url}/v1/Services")
        .with(body: hash_including('FriendlyName' => 'my-service'))
        .to_return(status: 201, body: svc_body, headers: { 'Content-Type' => 'application/json' })
      s = client.conversations_v1.services.create(friendly_name: 'my-service')
      expect(s.sid).to eq(is_sid)
    end

    it 'fetch + delete service' do
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}")
        .to_return(status: 200, body: svc_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Services/#{is_sid}").to_return(status: 204)
      expect(client.conversations_v1.services.fetch(is_sid).sid).to eq(is_sid)
      expect(client.conversations_v1.services.delete(is_sid)).to be_nil
    end

    it 'create_conversation under a service' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Conversations")
        .with(body: hash_including('FriendlyName' => 'svc-thread'))
        .to_return(status: 201, body: svc_conv_body, headers: { 'Content-Type' => 'application/json' })
      c = client.conversations_v1.services.create_conversation(is_sid, friendly_name: 'svc-thread')
      expect(c.sid).to eq(ch_sid)
      expect(c.chat_service_sid).to eq(is_sid)
    end
  end

  # ===========================================================================
  # Routes V2 PhoneNumber
  # ===========================================================================
  describe 'Routes V2 PhoneNumber' do
    let(:body) do
      { sid: qq_sid, phone_number: phone_number, account_sid: account_sid,
        friendly_name: 'support-line', voice_region: 'us1',
        url: "#{base_url}/v2/PhoneNumbers/#{phone_number}",
        date_created: '2026-06-27T12:00:00Z', date_updated: '2026-06-27T12:00:00Z' }.to_json
    end

    it 'fetch GETs /v2/PhoneNumbers/{number} (no account prefix)' do
      stub_request(:get, "#{base_url}/v2/PhoneNumbers/#{phone_number}")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      pn = client.routes_v2.phone_numbers.fetch(phone_number)
      expect(pn.sid).to eq(qq_sid)
      expect(pn.phone_number).to eq(phone_number)
      expect(pn.voice_region).to eq('us1')
    end

    it 'update POSTs VoiceRegion + FriendlyName as form' do
      stub_request(:post, "#{base_url}/v2/PhoneNumbers/#{phone_number}")
        .with(body: hash_including('VoiceRegion' => 'ie1', 'FriendlyName' => 'renamed'))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      client.routes_v2.phone_numbers.update(phone_number, voice_region: 'ie1', friendly_name: 'renamed')
    end

    it 'update partial sends only VoiceRegion' do
      stub_request(:post, "#{base_url}/v2/PhoneNumbers/#{phone_number}")
        .with(body: { 'VoiceRegion' => 'us1' })
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      client.routes_v2.phone_numbers.update(phone_number, voice_region: 'us1')
    end
  end
end
