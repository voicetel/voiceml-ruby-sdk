# frozen_string_literal: true

require 'spec_helper'

# Wire-shape tests for the v0.9.1 Assistants v1 surface — 7 families / 30 ops
# under `/v1/Assistants`, `/v1/Tools`, `/v1/Knowledge`, `/v1/Sessions`,
# `/v1/Policies`. Verifies that:
#   - the resource graph hangs off `client.assistants_v1`
#   - sub-scopes are reachable via `assistants(id)`, `knowledge(id)`,
#     `sessions(id)` factory methods
#   - HTTP method/path match the spec
#   - request bodies are JSON (snake_case keys) — distinct from the
#     form-urlencoded Conversations/Voice v1 surfaces
#   - response shapes round-trip (list envelopes + per-record fields)
RSpec.describe 'VoiceML v0.9.1 — Assistants v1' do
  let(:account_sid) { 'AC' + ('a' * 32) }
  let(:api_key)     { 'secret-key-9001' }
  let(:client)      { VoiceML::Client.new(account_sid: account_sid, api_key: api_key, base_url: base_url) }
  let(:base_url)    { 'https://voiceml.example.test' }

  let(:assistant_id) { 'aia_asst_abc123' }
  let(:tool_id)      { 'aia_tool_t1' }
  let(:knowledge_id) { 'aia_know_k1' }
  let(:session_id)   { 'sess_s1' }
  let(:message_id)   { 'aia_msg_m1' }
  let(:feedback_id)  { 'aia_fdbk_f1' }
  let(:policy_id)    { 'aia_plcy_p1' }

  def meta(url: nil)
    { first_page_url: url, next_page_url: nil, previous_page_url: nil,
      url: url, page: 0, page_size: 50, key: 'items' }
  end

  describe 'resource wiring' do
    it 'client.assistants_v1 is wired and exposes the 7 families' do
      r = client.assistants_v1
      expect(r).to be_a(VoiceML::AssistantsV1Resource)
      expect(r.assistants).to be_a(VoiceML::AssistantsV1AssistantsResource)
      expect(r.tools).to be_a(VoiceML::AssistantsV1ToolsResource)
      expect(r.knowledge).to be_a(VoiceML::AssistantsV1KnowledgeResource)
      expect(r.sessions).to be_a(VoiceML::AssistantsV1SessionsResource)
      expect(r.policies).to be_a(VoiceML::AssistantsV1PoliciesResource)
    end

    it 'assistants(id) returns a per-Assistant scope with sub-resources' do
      scope = client.assistants_v1.assistants(assistant_id)
      expect(scope).to be_a(VoiceML::AssistantsV1AssistantScope)
      expect(scope.assistant_id).to eq(assistant_id)
      expect(scope.tools).to be_a(VoiceML::AssistantsV1AssistantToolsScope)
      expect(scope.knowledge).to be_a(VoiceML::AssistantsV1AssistantKnowledgeScope)
      expect(scope.feedbacks).to be_a(VoiceML::AssistantsV1AssistantFeedbacksScope)
      expect(scope.messages).to be_a(VoiceML::AssistantsV1AssistantMessagesScope)
    end

    it 'knowledge(id) returns a per-Knowledge scope with status + chunks' do
      scope = client.assistants_v1.knowledge(knowledge_id)
      expect(scope).to be_a(VoiceML::AssistantsV1KnowledgeScope)
      expect(scope.knowledge_id).to eq(knowledge_id)
      expect(scope.status).to be_a(VoiceML::AssistantsV1KnowledgeStatusScope)
      expect(scope.chunks).to be_a(VoiceML::AssistantsV1KnowledgeChunksScope)
    end

    it 'sessions(id) returns a per-Session scope with messages' do
      scope = client.assistants_v1.sessions(session_id)
      expect(scope).to be_a(VoiceML::AssistantsV1SessionScope)
      expect(scope.session_id).to eq(session_id)
      expect(scope.messages).to be_a(VoiceML::AssistantsV1SessionMessagesScope)
    end
  end

  # ===========================================================================
  # Assistant — 5 CRUD
  # ===========================================================================
  describe 'Assistant' do
    let(:asst_body) do
      { account_sid: account_sid, id: assistant_id,
        name: 'support', owner: 'team-1',
        personality_prompt: 'Be helpful.', model: 'gpt-x',
        customer_ai: { 'perception_engine_enabled' => true },
        url: "#{base_url}/v1/Assistants/#{assistant_id}",
        date_created: 'x', date_updated: 'x' }.to_json
    end

    it 'create POSTs JSON with name + optional fields' do
      stub_request(:post, "#{base_url}/v1/Assistants")
        .with(
          body: hash_including('name' => 'support',
                                'owner' => 'team-1',
                                'personality_prompt' => 'Be helpful.',
                                'model' => 'gpt-x'),
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(status: 201, body: asst_body, headers: { 'Content-Type' => 'application/json' })

      a = client.assistants_v1.assistants.create(
        name: 'support', owner: 'team-1',
        personality_prompt: 'Be helpful.', model: 'gpt-x',
        customer_ai: { perception_engine_enabled: true }
      )
      expect(a).to be_a(VoiceML::AssistantsV1Assistant)
      expect(a.id).to eq(assistant_id)
      expect(a.name).to eq('support')
    end

    it 'list GETs /v1/Assistants and unwraps the assistants array' do
      payload = { assistants: [JSON.parse(asst_body)],
                  meta: meta(url: "#{base_url}/v1/Assistants") }.to_json
      stub_request(:get, "#{base_url}/v1/Assistants")
        .with(query: hash_including('PageSize' => '25'))
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })

      page = client.assistants_v1.assistants.list(page_size: 25)
      expect(page).to be_a(VoiceML::AssistantsV1AssistantList)
      expect(page.assistants.first.id).to eq(assistant_id)
      expect(page.page_size).to eq(50)
    end

    it 'fetch GETs /v1/Assistants/{id} and returns the AssistantWithToolsAndKnowledge shape' do
      fetch_body = { account_sid: account_sid, id: assistant_id,
                     name: 'support', owner: 'team-1',
                     personality_prompt: 'Be helpful.', model: 'gpt-x',
                     customer_ai: {},
                     url: "#{base_url}/v1/Assistants/#{assistant_id}",
                     date_created: 'x', date_updated: 'x',
                     tools: [{ id: tool_id, name: 'lookup', type: 'webhook',
                                enabled: true, requires_auth: false, meta: {},
                                description: '', date_created: 'x', date_updated: 'x' }],
                     knowledge: [{ id: knowledge_id, name: 'kb', type: 'file',
                                    date_created: 'x', date_updated: 'x' }] }.to_json
      stub_request(:get, "#{base_url}/v1/Assistants/#{assistant_id}")
        .to_return(status: 200, body: fetch_body, headers: { 'Content-Type' => 'application/json' })

      a = client.assistants_v1.assistants.fetch(assistant_id)
      expect(a).to be_a(VoiceML::AssistantsV1AssistantWithToolsAndKnowledge)
      expect(a.id).to eq(assistant_id)
      expect(a.tools.length).to eq(1)
      expect(a.tools.first['id']).to eq(tool_id)
      expect(a.knowledge.length).to eq(1)
      expect(a.knowledge.first['id']).to eq(knowledge_id)
    end

    it 'update PUTs JSON with the supplied subset of fields' do
      stub_request(:put, "#{base_url}/v1/Assistants/#{assistant_id}")
        .with(
          body: { 'personality_prompt' => 'Be concise.', 'model' => 'gpt-x2' },
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(status: 200, body: asst_body, headers: { 'Content-Type' => 'application/json' })

      a = client.assistants_v1.assistants.update(assistant_id,
        personality_prompt: 'Be concise.', model: 'gpt-x2'
      )
      expect(a.id).to eq(assistant_id)
    end

    it 'delete sends DELETE and returns nil on 204' do
      stub_request(:delete, "#{base_url}/v1/Assistants/#{assistant_id}")
        .to_return(status: 204)
      expect(client.assistants_v1.assistants.delete(assistant_id)).to be_nil
    end
  end

  # ===========================================================================
  # Tool — 5 CRUD + attach/detach + per-assistant list
  # ===========================================================================
  describe 'Tool' do
    let(:tool_body) do
      { account_sid: account_sid, id: tool_id, name: 'lookup',
        type: 'webhook', enabled: true, requires_auth: false, meta: {},
        description: 'Lookup orders',
        url: "#{base_url}/v1/Tools/#{tool_id}",
        date_created: 'x', date_updated: 'x' }.to_json
    end

    it 'create POSTs JSON with name + type + enabled (+ optional)' do
      stub_request(:post, "#{base_url}/v1/Tools")
        .with(
          body: hash_including('name' => 'lookup', 'type' => 'webhook',
                                'enabled' => true, 'assistant_id' => assistant_id,
                                'description' => 'Lookup orders'),
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(status: 201, body: tool_body, headers: { 'Content-Type' => 'application/json' })

      t = client.assistants_v1.tools.create(
        name: 'lookup', type: 'webhook', enabled: true,
        assistant_id: assistant_id, description: 'Lookup orders'
      )
      expect(t).to be_a(VoiceML::AssistantsV1Tool)
      expect(t.id).to eq(tool_id)
    end

    it 'list filters by AssistantId query param' do
      payload = { tools: [JSON.parse(tool_body)],
                  meta: meta(url: "#{base_url}/v1/Tools") }.to_json
      stub_request(:get, "#{base_url}/v1/Tools")
        .with(query: hash_including('AssistantId' => assistant_id, 'PageSize' => '10'))
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })

      page = client.assistants_v1.tools.list(assistant_id: assistant_id, page_size: 10)
      expect(page.tools.first.id).to eq(tool_id)
    end

    it 'fetch returns the ToolWithPolicies shape' do
      fetch_body = { account_sid: account_sid, id: tool_id, name: 'lookup',
                     type: 'webhook', enabled: true, requires_auth: false, meta: {},
                     description: 'd', date_created: 'x', date_updated: 'x',
                     policies: [{ id: policy_id, type: 'authentication',
                                   policy_details: { 'scheme' => 'bearer' },
                                   date_created: 'x', date_updated: 'x' }] }.to_json
      stub_request(:get, "#{base_url}/v1/Tools/#{tool_id}")
        .to_return(status: 200, body: fetch_body, headers: { 'Content-Type' => 'application/json' })

      t = client.assistants_v1.tools.fetch(tool_id)
      expect(t).to be_a(VoiceML::AssistantsV1ToolWithPolicies)
      expect(t.policies.length).to eq(1)
      expect(t.policies.first['id']).to eq(policy_id)
    end

    it 'update PUTs JSON with the supplied subset; delete sends DELETE' do
      stub_request(:put, "#{base_url}/v1/Tools/#{tool_id}")
        .with(body: { 'enabled' => false, 'description' => 'paused' },
              headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: tool_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Tools/#{tool_id}")
        .to_return(status: 204)

      expect(client.assistants_v1.tools.update(tool_id, enabled: false, description: 'paused').id)
        .to eq(tool_id)
      expect(client.assistants_v1.tools.delete(tool_id)).to be_nil
    end

    it 'attach POSTs /v1/Assistants/{id}/Tools/{toolId} (204 No Content -> nil)' do
      stub_request(:post, "#{base_url}/v1/Assistants/#{assistant_id}/Tools/#{tool_id}")
        .to_return(status: 204)
      expect(client.assistants_v1.assistants(assistant_id).tools.attach(tool_id)).to be_nil
    end

    it 'detach DELETEs /v1/Assistants/{id}/Tools/{toolId}' do
      stub_request(:delete, "#{base_url}/v1/Assistants/#{assistant_id}/Tools/#{tool_id}")
        .to_return(status: 204)
      expect(client.assistants_v1.assistants(assistant_id).tools.detach(tool_id)).to be_nil
    end

    it 'per-assistant list GETs /v1/Assistants/{id}/Tools' do
      payload = { tools: [JSON.parse(tool_body)],
                  meta: meta(url: "#{base_url}/v1/Assistants/#{assistant_id}/Tools") }.to_json
      stub_request(:get, "#{base_url}/v1/Assistants/#{assistant_id}/Tools")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = client.assistants_v1.assistants(assistant_id).tools.list
      expect(page.tools.first.id).to eq(tool_id)
    end
  end

  # ===========================================================================
  # Knowledge — 5 CRUD + status + chunks + attach/detach + per-assistant list
  # ===========================================================================
  describe 'Knowledge' do
    let(:know_body) do
      { account_sid: account_sid, id: knowledge_id, name: 'kb',
        type: 'file', status: 'ready', embedding_model: 'text-embedding-3',
        description: 'Manuals', knowledge_source_details: { 'source' => 's3://x/y' },
        url: "#{base_url}/v1/Knowledge/#{knowledge_id}",
        date_created: 'x', date_updated: 'x' }.to_json
    end

    it 'create POSTs JSON with name + type (+ optional)' do
      stub_request(:post, "#{base_url}/v1/Knowledge")
        .with(
          body: hash_including('name' => 'kb', 'type' => 'file',
                                'assistant_id' => assistant_id,
                                'description' => 'Manuals',
                                'embedding_model' => 'text-embedding-3'),
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(status: 201, body: know_body, headers: { 'Content-Type' => 'application/json' })

      k = client.assistants_v1.knowledge.create(
        name: 'kb', type: 'file', assistant_id: assistant_id,
        description: 'Manuals', embedding_model: 'text-embedding-3',
        knowledge_source_details: { source: 's3://x/y' }
      )
      expect(k).to be_a(VoiceML::AssistantsV1Knowledge)
      expect(k.id).to eq(knowledge_id)
    end

    it 'list filters by AssistantId query param' do
      payload = { knowledge: [JSON.parse(know_body)],
                  meta: meta(url: "#{base_url}/v1/Knowledge") }.to_json
      stub_request(:get, "#{base_url}/v1/Knowledge")
        .with(query: hash_including('AssistantId' => assistant_id))
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })

      page = client.assistants_v1.knowledge.list(assistant_id: assistant_id)
      expect(page.knowledge.first.id).to eq(knowledge_id)
    end

    it 'fetch + update + delete round-trip' do
      stub_request(:get, "#{base_url}/v1/Knowledge/#{knowledge_id}")
        .to_return(status: 200, body: know_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:put, "#{base_url}/v1/Knowledge/#{knowledge_id}")
        .with(body: { 'description' => 'updated' },
              headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: know_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}/v1/Knowledge/#{knowledge_id}")
        .to_return(status: 204)

      expect(client.assistants_v1.knowledge.fetch(knowledge_id).id).to eq(knowledge_id)
      expect(client.assistants_v1.knowledge.update(knowledge_id, description: 'updated').id)
        .to eq(knowledge_id)
      expect(client.assistants_v1.knowledge.delete(knowledge_id)).to be_nil
    end

    it 'status.fetch GETs /v1/Knowledge/{id}/Status' do
      status_body = { account_sid: account_sid, status: 'ready',
                      last_status: 'indexing', date_updated: 'x' }.to_json
      stub_request(:get, "#{base_url}/v1/Knowledge/#{knowledge_id}/Status")
        .to_return(status: 200, body: status_body, headers: { 'Content-Type' => 'application/json' })

      s = client.assistants_v1.knowledge(knowledge_id).status.fetch
      expect(s).to be_a(VoiceML::AssistantsV1KnowledgeStatus)
      expect(s.status).to eq('ready')
      expect(s.last_status).to eq('indexing')
    end

    it 'chunks.list GETs /v1/Knowledge/{id}/Chunks and returns chunks array' do
      chunk = { account_sid: account_sid, content: 'a paragraph',
                metadata: { 'page' => 1 }, date_created: 'x', date_updated: 'x' }
      payload = { chunks: [chunk],
                  meta: meta(url: "#{base_url}/v1/Knowledge/#{knowledge_id}/Chunks") }.to_json
      stub_request(:get, "#{base_url}/v1/Knowledge/#{knowledge_id}/Chunks")
        .with(query: hash_including('PageSize' => '5'))
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })

      page = client.assistants_v1.knowledge(knowledge_id).chunks.list(page_size: 5)
      expect(page).to be_a(VoiceML::AssistantsV1KnowledgeChunkList)
      expect(page.chunks.first.content).to eq('a paragraph')
    end

    it 'attach POSTs /v1/Assistants/{id}/Knowledge/{knowledgeId}' do
      stub_request(:post, "#{base_url}/v1/Assistants/#{assistant_id}/Knowledge/#{knowledge_id}")
        .to_return(status: 204)
      expect(client.assistants_v1.assistants(assistant_id).knowledge.attach(knowledge_id)).to be_nil
    end

    it 'detach DELETEs /v1/Assistants/{id}/Knowledge/{knowledgeId}' do
      stub_request(:delete, "#{base_url}/v1/Assistants/#{assistant_id}/Knowledge/#{knowledge_id}")
        .to_return(status: 204)
      expect(client.assistants_v1.assistants(assistant_id).knowledge.detach(knowledge_id)).to be_nil
    end

    it 'per-assistant list GETs /v1/Assistants/{id}/Knowledge' do
      payload = { knowledge: [JSON.parse(know_body)],
                  meta: meta(url: "#{base_url}/v1/Assistants/#{assistant_id}/Knowledge") }.to_json
      stub_request(:get, "#{base_url}/v1/Assistants/#{assistant_id}/Knowledge")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = client.assistants_v1.assistants(assistant_id).knowledge.list
      expect(page.knowledge.first.id).to eq(knowledge_id)
    end
  end

  # ===========================================================================
  # Session (list + fetch) + Session.messages.list
  # ===========================================================================
  describe 'Session' do
    let(:sess_body) do
      { id: session_id, account_sid: account_sid, assistant_id: assistant_id,
        verified: true, identity: 'user-1',
        date_created: 'x', date_updated: 'x' }.to_json
    end

    it 'list GETs /v1/Sessions and unwraps the sessions array' do
      payload = { sessions: [JSON.parse(sess_body)],
                  meta: meta(url: "#{base_url}/v1/Sessions") }.to_json
      stub_request(:get, "#{base_url}/v1/Sessions")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = client.assistants_v1.sessions.list
      expect(page).to be_a(VoiceML::AssistantsV1SessionList)
      expect(page.sessions.first.id).to eq(session_id)
    end

    it 'fetch GETs /v1/Sessions/{id}' do
      stub_request(:get, "#{base_url}/v1/Sessions/#{session_id}")
        .to_return(status: 200, body: sess_body, headers: { 'Content-Type' => 'application/json' })
      s = client.assistants_v1.sessions.fetch(session_id)
      expect(s).to be_a(VoiceML::AssistantsV1Session)
      expect(s.assistant_id).to eq(assistant_id)
    end

    it 'sessions(id).messages.list GETs /v1/Sessions/{id}/Messages' do
      msg = { id: message_id, account_sid: account_sid, assistant_id: assistant_id,
              session_id: session_id, identity: 'user-1', role: 'assistant',
              content: { 'text' => 'hi' }, meta: {},
              date_created: 'x', date_updated: 'x' }
      payload = { messages: [msg],
                  meta: meta(url: "#{base_url}/v1/Sessions/#{session_id}/Messages") }.to_json
      stub_request(:get, "#{base_url}/v1/Sessions/#{session_id}/Messages")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })
      page = client.assistants_v1.sessions(session_id).messages.list
      expect(page).to be_a(VoiceML::AssistantsV1MessageList)
      expect(page.messages.first.id).to eq(message_id)
      expect(page.messages.first.role).to eq('assistant')
    end
  end

  # ===========================================================================
  # Send Message (POST /v1/Assistants/{id}/Messages)
  # ===========================================================================
  describe 'Send Message' do
    it 'POSTs JSON with identity + body (+ session_id + webhook + mode) and returns SendMessageResponse' do
      reply = { status: 'ok', session_id: session_id, account_sid: account_sid,
                body: 'Hello there.', flagged: false, aborted: false }.to_json
      stub_request(:post, "#{base_url}/v1/Assistants/#{assistant_id}/Messages")
        .with(
          body: hash_including('identity' => 'user-1', 'body' => 'Hi assistant',
                                'session_id' => session_id, 'webhook' => 'https://example.com/hk',
                                'mode' => 'sync'),
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(status: 200, body: reply, headers: { 'Content-Type' => 'application/json' })

      r = client.assistants_v1.assistants(assistant_id).messages.create(
        identity: 'user-1', body: 'Hi assistant',
        session_id: session_id, webhook: 'https://example.com/hk', mode: 'sync'
      )
      expect(r).to be_a(VoiceML::AssistantsV1SendMessageResponse)
      expect(r.status).to eq('ok')
      expect(r.session_id).to eq(session_id)
      expect(r.body).to eq('Hello there.')
      expect(r.flagged).to be false
    end
  end

  # ===========================================================================
  # Feedback — list + create under /v1/Assistants/{id}/Feedbacks
  # ===========================================================================
  describe 'Feedback' do
    let(:fb_body) do
      { id: feedback_id, account_sid: account_sid, assistant_id: assistant_id,
        session_id: session_id, message_id: message_id, score: 0.9,
        text: 'helpful', date_created: 'x', date_updated: 'x' }.to_json
    end

    it 'list GETs /v1/Assistants/{id}/Feedbacks and unwraps the feedbacks array' do
      payload = { feedbacks: [JSON.parse(fb_body)],
                  meta: meta(url: "#{base_url}/v1/Assistants/#{assistant_id}/Feedbacks") }.to_json
      stub_request(:get, "#{base_url}/v1/Assistants/#{assistant_id}/Feedbacks")
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })

      page = client.assistants_v1.assistants(assistant_id).feedbacks.list
      expect(page).to be_a(VoiceML::AssistantsV1FeedbackList)
      expect(page.feedbacks.first.id).to eq(feedback_id)
      expect(page.feedbacks.first.score).to eq(0.9)
    end

    it 'create POSTs JSON with session_id + message_id + score + text' do
      stub_request(:post, "#{base_url}/v1/Assistants/#{assistant_id}/Feedbacks")
        .with(
          body: { 'session_id' => session_id, 'message_id' => message_id,
                  'score' => 0.9, 'text' => 'helpful' },
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(status: 201, body: fb_body, headers: { 'Content-Type' => 'application/json' })

      fb = client.assistants_v1.assistants(assistant_id).feedbacks.create(
        session_id: session_id, message_id: message_id,
        score: 0.9, text: 'helpful'
      )
      expect(fb).to be_a(VoiceML::AssistantsV1Feedback)
      expect(fb.id).to eq(feedback_id)
    end
  end

  # ===========================================================================
  # Policy — list /v1/Policies
  # ===========================================================================
  describe 'Policy' do
    it 'list filters by ToolId + KnowledgeId + PageSize' do
      policy = { id: policy_id, name: 'auth', type: 'authentication',
                 policy_details: { 'scheme' => 'bearer' },
                 date_created: 'x', date_updated: 'x' }
      payload = { policies: [policy],
                  meta: meta(url: "#{base_url}/v1/Policies") }.to_json
      stub_request(:get, "#{base_url}/v1/Policies")
        .with(query: hash_including('ToolId' => tool_id,
                                     'KnowledgeId' => knowledge_id,
                                     'PageSize' => '20'))
        .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })

      page = client.assistants_v1.policies.list(
        tool_id: tool_id, knowledge_id: knowledge_id, page_size: 20
      )
      expect(page).to be_a(VoiceML::AssistantsV1PolicyList)
      expect(page.policies.first.id).to eq(policy_id)
      expect(page.policies.first.type).to eq('authentication')
    end
  end
end
