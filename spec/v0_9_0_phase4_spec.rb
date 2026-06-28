# frozen_string_literal: true

require 'spec_helper'

# Wire-shape tests for the Phase 4 service-scoped Conversations v1 surface
# (#421 Conversations v1, 15 sub-resource families under
# /v1/Services/{ChatServiceSid}/...). Verifies that the scope object is wired
# on the client, that paths/methods match the spec, and that snake_case kwargs
# map to the PascalCase wire field names the server expects.
RSpec.describe 'VoiceML v0.9.0 Phase 4 — service-scoped Conversations v1' do
  let(:account_sid) { 'AC' + ('a' * 32) }
  let(:api_key)     { 'secret-key-9000' }
  let(:client)      { VoiceML::Client.new(account_sid: account_sid, api_key: api_key, base_url: base_url) }
  let(:base_url)    { 'https://voiceml.example.test' }

  let(:is_sid) { 'IS' + ('0' * 32) }
  let(:ch_sid) { 'CH' + ('7' * 32) }
  let(:im_sid) { 'IM' + ('8' * 32) }
  let(:mb_sid) { 'MB' + ('9' * 32) }
  let(:dy_sid) { 'DY' + ('a' * 32) }
  let(:wh_sid) { 'WH' + ('b' * 32) }
  let(:rl_sid) { 'RL' + ('c' * 32) }
  let(:us_sid) { 'US' + ('d' * 32) }
  let(:bs_sid) { 'BS' + ('e' * 32) }

  let(:scope) { client.conversations_v1.services.scope(is_sid) }

  def meta(url: nil)
    { first_page_url: url, next_page_url: nil, previous_page_url: nil,
      url: url, page: 0, page_size: 50, key: 'items' }
  end

  describe 'scope wiring' do
    it 'services.scope(IS_sid) returns a ConversationsV1ServiceScopeResource' do
      expect(scope).to be_a(VoiceML::ConversationsV1ServiceScopeResource)
      expect(scope.chat_service_sid).to eq(is_sid)
    end
  end

  # ===========================================================================
  # ServiceConversation
  # ===========================================================================
  describe 'ServiceConversation' do
    let(:body) do
      { sid: ch_sid, account_sid: account_sid, chat_service_sid: is_sid,
        state: 'active', attributes: '{}', friendly_name: 'svc-thread',
        date_created: 'x', date_updated: 'x',
        url: "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}" }.to_json
    end

    it 'create POSTs FriendlyName / UniqueName / State / Attributes / Timers.*' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Conversations")
        .with(body: hash_including(
          'FriendlyName' => 'svc-thread', 'UniqueName' => 'svc-1',
          'State' => 'active', 'Attributes' => '{}',
          'Timers.Inactive' => 'PT1H', 'Timers.Closed' => 'PT24H',
          'MessagingServiceSid' => 'MG' + 'f' * 32
        ))
        .to_return(status: 201, body: body, headers: { 'Content-Type' => 'application/json' })
      c = scope.create_conversation(
        friendly_name: 'svc-thread', unique_name: 'svc-1',
        state: 'active', attributes: '{}',
        timers_inactive: 'PT1H', timers_closed: 'PT24H',
        messaging_service_sid: 'MG' + 'f' * 32
      )
      expect(c.sid).to eq(ch_sid)
      expect(c.chat_service_sid).to eq(is_sid)
    end

    it 'list, fetch, update, delete' do
      payload = { conversations: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/Services/#{is_sid}/Conversations") }.to_json
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Conversations")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}")
        .with(body: hash_including('State' => 'closed'))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}")
        .to_return(status: 204)

      expect(scope.list_conversations.conversations.first.sid).to eq(ch_sid)
      expect(scope.fetch_conversation(ch_sid).sid).to eq(ch_sid)
      expect(scope.update_conversation(ch_sid, state: 'closed').sid).to eq(ch_sid)
      expect(scope.delete_conversation(ch_sid)).to be_nil
    end
  end

  # ===========================================================================
  # ServiceConversationMessage
  # ===========================================================================
  describe 'ServiceConversationMessage' do
    let(:body) do
      { sid: im_sid, account_sid: account_sid, chat_service_sid: is_sid,
        conversation_sid: ch_sid, index: 0, author: '+15551234567',
        body: 'Hi', attributes: '{}',
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create POSTs Author + Body + ContentSid' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Messages")
        .with(body: hash_including('Author' => '+15551234567',
                                    'Body' => 'Hi',
                                    'ContentSid' => 'HX' + 'a' * 32))
        .to_return(status: 201, body: body, headers: { 'Content-Type' => 'application/json' })
      m = scope.create_message(ch_sid,
            author: '+15551234567', body: 'Hi', content_sid: 'HX' + 'a' * 32)
      expect(m.sid).to eq(im_sid)
      expect(m.chat_service_sid).to eq(is_sid)
    end

    it 'list + fetch + update + delete' do
      payload = { messages: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Messages") }.to_json
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Messages")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Messages/#{im_sid}")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Messages/#{im_sid}")
        .with(body: hash_including('Body' => 'edited'))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Messages/#{im_sid}")
        .to_return(status: 204)

      expect(scope.list_messages(ch_sid).messages.first.sid).to eq(im_sid)
      expect(scope.fetch_message(ch_sid, im_sid).sid).to eq(im_sid)
      expect(scope.update_message(ch_sid, im_sid, body: 'edited').sid).to eq(im_sid)
      expect(scope.delete_message(ch_sid, im_sid)).to be_nil
    end
  end

  # ===========================================================================
  # ServiceConversationMessageReceipt
  # ===========================================================================
  describe 'ServiceConversationMessageReceipt' do
    let(:body) do
      { sid: dy_sid, account_sid: account_sid, chat_service_sid: is_sid,
        conversation_sid: ch_sid, message_sid: im_sid,
        status: 'delivered', error_code: 0,
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'list_message_receipts returns delivery_receipts array' do
      payload = { delivery_receipts: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Messages/#{im_sid}/Receipts") }.to_json
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Messages/#{im_sid}/Receipts")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = scope.list_message_receipts(ch_sid, im_sid)
      expect(page.delivery_receipts.first.sid).to eq(dy_sid)
      expect(page.delivery_receipts.first.status).to eq('delivered')
    end

    it 'fetch_message_receipt' do
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Messages/#{im_sid}/Receipts/#{dy_sid}")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      r = scope.fetch_message_receipt(ch_sid, im_sid, dy_sid)
      expect(r.sid).to eq(dy_sid)
      expect(r.chat_service_sid).to eq(is_sid)
    end
  end

  # ===========================================================================
  # ServiceConversationParticipant
  # ===========================================================================
  describe 'ServiceConversationParticipant' do
    let(:body) do
      { sid: mb_sid, account_sid: account_sid, chat_service_sid: is_sid,
        conversation_sid: ch_sid, identity: 'alice', attributes: '{}',
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create POSTs Identity + MessagingBinding.* + RoleSid' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Participants")
        .with(body: hash_including(
          'Identity' => 'alice',
          'RoleSid' => rl_sid,
          'MessagingBinding.Address' => '+18005550000',
          'MessagingBinding.ProxyAddress' => '+18005551111',
          'MessagingBinding.ProjectedAddress' => '+18005552222'
        ))
        .to_return(status: 201, body: body, headers: { 'Content-Type' => 'application/json' })
      p = scope.create_participant(ch_sid,
            identity: 'alice', role_sid: rl_sid,
            messaging_binding_address: '+18005550000',
            messaging_binding_proxy_address: '+18005551111',
            messaging_binding_projected_address: '+18005552222')
      expect(p.sid).to eq(mb_sid)
    end

    it 'update only sends Attributes + RoleSid (Identity is not updatable)' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Participants/#{mb_sid}")
        .with(body: { 'Attributes' => '{"a":1}', 'RoleSid' => rl_sid })
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      scope.update_participant(ch_sid, mb_sid,
        identity: 'should-be-dropped', attributes: '{"a":1}', role_sid: rl_sid)
    end

    it 'list + fetch + delete' do
      payload = { participants: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Participants") }.to_json
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Participants")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Participants/#{mb_sid}")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Participants/#{mb_sid}")
        .to_return(status: 204)

      expect(scope.list_participants(ch_sid).participants.first.sid).to eq(mb_sid)
      expect(scope.fetch_participant(ch_sid, mb_sid).sid).to eq(mb_sid)
      expect(scope.delete_participant(ch_sid, mb_sid)).to be_nil
    end
  end

  # ===========================================================================
  # ServiceConversationScopedWebhook
  # ===========================================================================
  describe 'ServiceConversationScopedWebhook' do
    let(:body) do
      { sid: wh_sid, account_sid: account_sid, chat_service_sid: is_sid,
        conversation_sid: ch_sid, target: 'webhook',
        configuration: { 'url' => 'https://example.com/hook' },
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create POSTs Target + Configuration.Url + Configuration.Method' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Webhooks")
        .with(body: hash_including('Target' => 'webhook',
                                    'Configuration.Url' => 'https://example.com/hook',
                                    'Configuration.Method' => 'POST'))
        .to_return(status: 201, body: body, headers: { 'Content-Type' => 'application/json' })
      w = scope.create_webhook(ch_sid,
            target: 'webhook',
            configuration_url: 'https://example.com/hook',
            configuration_method: 'POST')
      expect(w.sid).to eq(wh_sid)
    end

    it 'update sends only Configuration.* fields (not Target)' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Webhooks/#{wh_sid}")
        .with(body: { 'Configuration.Url' => 'https://example.com/new',
                      'Configuration.Method' => 'GET' })
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      scope.update_webhook(ch_sid, wh_sid,
        target: 'should-be-dropped',
        configuration_url: 'https://example.com/new',
        configuration_method: 'GET')
    end

    it 'list + fetch + delete' do
      payload = { webhooks: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Webhooks") }.to_json
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Webhooks")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Webhooks/#{wh_sid}")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Services/#{is_sid}/Conversations/#{ch_sid}/Webhooks/#{wh_sid}")
        .to_return(status: 204)

      expect(scope.list_webhooks(ch_sid).webhooks.first.sid).to eq(wh_sid)
      expect(scope.fetch_webhook(ch_sid, wh_sid).sid).to eq(wh_sid)
      expect(scope.delete_webhook(ch_sid, wh_sid)).to be_nil
    end
  end

  # ===========================================================================
  # ServiceConversationWithParticipants
  # ===========================================================================
  describe 'ServiceConversationWithParticipants' do
    let(:body) do
      { sid: ch_sid, account_sid: account_sid, chat_service_sid: is_sid,
        state: 'active', attributes: '{}',
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create POSTs FriendlyName + repeated Participant' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/ConversationWithParticipants")
        .with { |req| req.body.include?('FriendlyName=group-chat') &&
                       req.body.scan('Participant=').length == 2 }
        .to_return(status: 201, body: body, headers: { 'Content-Type' => 'application/json' })
      c = scope.create_conversation_with_participants(
        friendly_name: 'group-chat',
        participant: ['{"identity":"alice"}', '{"identity":"bob"}']
      )
      expect(c.sid).to eq(ch_sid)
      expect(c.chat_service_sid).to eq(is_sid)
    end
  end

  # ===========================================================================
  # ServiceParticipantConversation
  # ===========================================================================
  describe 'ServiceParticipantConversation' do
    let(:body) do
      { account_sid: account_sid, chat_service_sid: is_sid,
        participant_identity: 'alice', conversation_sid: ch_sid,
        conversation_state: 'active',
        conversation_date_created: 'x', conversation_date_updated: 'x' }.to_json
    end

    it 'list filters by Identity + Address' do
      payload = { conversations: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/Services/#{is_sid}/ParticipantConversations") }.to_json
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/ParticipantConversations")
        .with(query: hash_including('Identity' => 'alice', 'Address' => '+18005551234'))
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = scope.list_participant_conversations(identity: 'alice', address: '+18005551234')
      expect(page.conversations.first.participant_identity).to eq('alice')
      expect(page.conversations.first.chat_service_sid).to eq(is_sid)
    end
  end

  # ===========================================================================
  # ServiceUserConversation
  # ===========================================================================
  describe 'ServiceUserConversation' do
    let(:body) do
      { account_sid: account_sid, chat_service_sid: is_sid,
        conversation_sid: ch_sid, user_sid: us_sid,
        conversation_state: 'active', notification_level: 'default',
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'list under /Users/{UserSid}/Conversations' do
      payload = { conversations: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/Services/#{is_sid}/Users/#{us_sid}/Conversations") }.to_json
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Users/#{us_sid}/Conversations")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = scope.list_user_conversations(us_sid)
      expect(page.conversations.first.user_sid).to eq(us_sid)
      expect(page.conversations.first.notification_level).to eq('default')
    end
  end

  # ===========================================================================
  # ServiceRole
  # ===========================================================================
  describe 'ServiceRole' do
    let(:body) do
      { sid: rl_sid, account_sid: account_sid, chat_service_sid: is_sid,
        friendly_name: 'svc-admin', type: 'service',
        permissions: %w[editAnyMessage deleteAnyMessage],
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create POSTs FriendlyName + Type + repeated Permission' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Roles")
        .with { |req| req.body.include?('FriendlyName=svc-admin') &&
                       req.body.include?('Type=service') &&
                       req.body.scan('Permission=').length == 2 }
        .to_return(status: 201, body: body, headers: { 'Content-Type' => 'application/json' })
      r = scope.create_role(
        friendly_name: 'svc-admin', type: 'service',
        permission: %w[editAnyMessage deleteAnyMessage]
      )
      expect(r.sid).to eq(rl_sid)
      expect(r.chat_service_sid).to eq(is_sid)
    end

    it 'update accepts a single Permission string and wraps it in an array' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Roles/#{rl_sid}")
        .with { |req| req.body.scan('Permission=').length == 1 }
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      scope.update_role(rl_sid, permission: 'editAnyMessage')
    end

    it 'list + fetch + delete' do
      payload = { roles: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/Services/#{is_sid}/Roles") }.to_json
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Roles")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Roles/#{rl_sid}")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Services/#{is_sid}/Roles/#{rl_sid}")
        .to_return(status: 204)

      expect(scope.list_roles.roles.first.sid).to eq(rl_sid)
      expect(scope.fetch_role(rl_sid).sid).to eq(rl_sid)
      expect(scope.delete_role(rl_sid)).to be_nil
    end
  end

  # ===========================================================================
  # ServiceUser
  # ===========================================================================
  describe 'ServiceUser' do
    let(:body) do
      { sid: us_sid, account_sid: account_sid, chat_service_sid: is_sid,
        identity: 'alice', friendly_name: 'Alice', attributes: '{}',
        is_online: true, is_notifiable: false,
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'create POSTs Identity + FriendlyName + RoleSid' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Users")
        .with(body: hash_including('Identity' => 'alice',
                                    'FriendlyName' => 'Alice',
                                    'RoleSid' => rl_sid))
        .to_return(status: 201, body: body, headers: { 'Content-Type' => 'application/json' })
      u = scope.create_user(identity: 'alice', friendly_name: 'Alice', role_sid: rl_sid)
      expect(u.sid).to eq(us_sid)
      expect(u.chat_service_sid).to eq(is_sid)
    end

    it 'update only sends FriendlyName / Attributes / RoleSid' do
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Users/#{us_sid}")
        .with(body: { 'FriendlyName' => 'Alicia', 'Attributes' => '{"vip":true}' })
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      scope.update_user(us_sid,
        identity: 'should-be-dropped',
        friendly_name: 'Alicia', attributes: '{"vip":true}')
    end

    it 'list + fetch + delete' do
      payload = { users: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/Services/#{is_sid}/Users") }.to_json
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Users")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Users/#{us_sid}")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Services/#{is_sid}/Users/#{us_sid}")
        .to_return(status: 204)

      expect(scope.list_users.users.first.sid).to eq(us_sid)
      expect(scope.fetch_user(us_sid).sid).to eq(us_sid)
      expect(scope.delete_user(us_sid)).to be_nil
    end
  end

  # ===========================================================================
  # ServiceBinding
  # ===========================================================================
  describe 'ServiceBinding' do
    let(:body) do
      { sid: bs_sid, account_sid: account_sid, chat_service_sid: is_sid,
        binding_type: 'apn', identity: 'alice',
        endpoint: 'ios-device-1', message_types: %w[new_message],
        date_created: 'x', date_updated: 'x', url: 'x' }.to_json
    end

    it 'list filters by BindingType + Identity' do
      payload = { bindings: [JSON.parse(body)],
                  meta: meta(url: "#{base_url}/v1/Services/#{is_sid}/Bindings") }.to_json
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Bindings")
        .with(query: hash_including('BindingType' => 'apn', 'Identity' => 'alice'))
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = scope.list_bindings(binding_type: 'apn', identity: 'alice')
      expect(page.bindings.first.sid).to eq(bs_sid)
      expect(page.bindings.first.binding_type).to eq('apn')
    end

    it 'fetch + delete' do
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Bindings/#{bs_sid}")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Services/#{is_sid}/Bindings/#{bs_sid}")
        .to_return(status: 204)

      expect(scope.fetch_binding(bs_sid).sid).to eq(bs_sid)
      expect(scope.delete_binding(bs_sid)).to be_nil
    end
  end

  # ===========================================================================
  # ServiceConfiguration
  # ===========================================================================
  describe 'ServiceConfiguration' do
    let(:body) do
      { chat_service_sid: is_sid, default_chat_service_role_sid: rl_sid,
        default_conversation_creator_role_sid: rl_sid,
        default_conversation_role_sid: rl_sid,
        reachability_enabled: true,
        url: "#{base_url}/v1/Services/#{is_sid}/Configuration" }.to_json
    end

    it 'fetch + update Configuration singleton' do
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Configuration")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Configuration")
        .with(body: hash_including('DefaultChatServiceRoleSid' => rl_sid,
                                    'ReachabilityEnabled' => 'true'))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

      expect(scope.fetch_configuration.chat_service_sid).to eq(is_sid)
      scope.update_configuration(default_chat_service_role_sid: rl_sid,
                                  reachability_enabled: true)
    end
  end

  # ===========================================================================
  # ServiceNotification
  # ===========================================================================
  describe 'ServiceNotification' do
    let(:body) do
      { account_sid: account_sid, chat_service_sid: is_sid,
        log_enabled: true, new_message: { 'enabled' => true },
        url: "#{base_url}/v1/Services/#{is_sid}/Configuration/Notifications" }.to_json
    end

    it 'fetch + update Notifications singleton with dotted-form fields' do
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Configuration/Notifications")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Configuration/Notifications")
        .with(body: hash_including(
          'LogEnabled' => 'true',
          'NewMessage.Enabled' => 'true',
          'NewMessage.Template' => 'You have a new message',
          'NewMessage.BadgeCountEnabled' => 'true',
          'NewMessage.WithMedia.Enabled' => 'false',
          'AddedToConversation.Enabled' => 'true',
          'RemovedFromConversation.Sound' => 'bell.aiff'
        ))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

      expect(scope.fetch_notifications.chat_service_sid).to eq(is_sid)
      scope.update_notifications(
        log_enabled: true,
        new_message_enabled: true,
        new_message_template: 'You have a new message',
        new_message_badge_count_enabled: true,
        new_message_with_media_enabled: false,
        added_to_conversation_enabled: true,
        removed_from_conversation_sound: 'bell.aiff'
      )
    end
  end

  # ===========================================================================
  # ServiceWebhookConfiguration
  # ===========================================================================
  describe 'ServiceWebhookConfiguration' do
    let(:body) do
      { account_sid: account_sid, chat_service_sid: is_sid,
        method: 'POST', pre_webhook_url: 'https://example.com/pre',
        post_webhook_url: 'https://example.com/post',
        filters: %w[onMessageAdded onMessageRemoved],
        url: "#{base_url}/v1/Services/#{is_sid}/Configuration/Webhooks" }.to_json
    end

    it 'fetch + update WebhookConfiguration singleton with repeated Filters' do
      stub_request(:get, "#{base_url}/v1/Services/#{is_sid}/Configuration/Webhooks")
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}/v1/Services/#{is_sid}/Configuration/Webhooks")
        .with { |req| req.body.include?('Method=POST') &&
                       req.body.include?('PreWebhookUrl=') &&
                       req.body.scan('Filters=').length == 2 }
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

      expect(scope.fetch_webhook_configuration.method).to eq('POST')
      scope.update_webhook_configuration(
        method: 'POST',
        pre_webhook_url: 'https://example.com/pre',
        post_webhook_url: 'https://example.com/post',
        filters: %w[onMessageAdded onMessageRemoved]
      )
    end
  end
end
