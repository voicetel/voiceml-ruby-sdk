# frozen_string_literal: true

require_relative '../models/assistants_v1'

module VoiceML
  # `client.assistants_v1` — Twilio AI-Assistants v1 (assistants.twilio.com/v1).
  # Sits outside the /2010-04-01/Accounts/... namespace; account resolved from Basic auth.
  # 7 families / 30 ops:
  #   - Assistant (5 CRUD)
  #   - Tool (5 CRUD + attach/detach + per-assistant list)
  #   - Knowledge (5 CRUD + status fetch + chunks list + attach/detach + per-assistant list)
  #   - Session (list + fetch + per-session messages list)
  #   - Message send (POST /v1/Assistants/{id}/Messages)
  #   - Feedback (list + create under /v1/Assistants/{id}/Feedbacks)
  #   - Policy (list /v1/Policies)
  #
  # Wire format: application/json request bodies (snake_case keys) — distinct from
  # the form-urlencoded Conversations/Voice v1 surfaces. Responses are JSON with the
  # shared `meta` envelope (V1Pageable).
  class AssistantsV1Resource
    def initialize(transport)
      @transport         = transport
      @assistants_top    = AssistantsV1AssistantsResource.new(transport)
      @tools_top         = AssistantsV1ToolsResource.new(transport)
      @knowledge_top     = AssistantsV1KnowledgeResource.new(transport)
      @sessions_top      = AssistantsV1SessionsResource.new(transport)
      @policies_top      = AssistantsV1PoliciesResource.new(transport)
    end

    # Scope factory: with no arg, returns the top-level Assistants resource
    # (list/create/fetch/update/delete). With an `assistant_id`, returns the
    # nested scope exposing `.tools`, `.knowledge`, `.feedbacks`, `.messages`.
    def assistants(assistant_id = nil)
      assistant_id.nil? ? @assistants_top : AssistantsV1AssistantScope.new(@transport, assistant_id)
    end

    # Top-level Tools resource (list/create/fetch/update/delete on /v1/Tools).
    def tools
      @tools_top
    end

    # Scope factory: with no arg, returns the top-level Knowledge resource
    # (list/create/fetch/update/delete). With a `knowledge_id`, returns the
    # nested scope exposing `.status` and `.chunks`.
    def knowledge(knowledge_id = nil)
      knowledge_id.nil? ? @knowledge_top : AssistantsV1KnowledgeScope.new(@transport, knowledge_id)
    end

    # Scope factory: with no arg, returns the top-level Sessions resource
    # (list/fetch on /v1/Sessions). With a `session_id`, returns the nested
    # scope exposing `.messages`.
    def sessions(session_id = nil)
      session_id.nil? ? @sessions_top : AssistantsV1SessionScope.new(@transport, session_id)
    end

    def policies
      @policies_top
    end
  end

  # ============================================================================
  # /v1/Assistants — 5 CRUD ops on the top-level Assistant resource.
  # Fetch returns the AssistantWithToolsAndKnowledge shape (tools + knowledge inline).
  # ============================================================================
  class AssistantsV1AssistantsResource
    CREATE_FIELDS = %i[name owner personality_prompt model customer_ai segment_credential].freeze
    UPDATE_FIELDS = %i[name owner personality_prompt model customer_ai segment_credential].freeze

    def initialize(transport)
      @transport = transport
    end

    def list(page_size: nil, page: nil, page_token: nil)
      params = {}
      params['PageSize']  = page_size  unless page_size.nil?
      params['Page']      = page       unless page.nil?
      params['PageToken'] = page_token unless page_token.nil?
      AssistantsV1AssistantList.new(@transport.request(:get, '/v1/Assistants', params: params))
    end

    def create(name:, **kwargs)
      kwargs[:name] = name
      AssistantsV1Assistant.from_hash(
        @transport.request(:post, '/v1/Assistants', json: build_json(CREATE_FIELDS, kwargs))
      )
    end

    def fetch(id)
      AssistantsV1AssistantWithToolsAndKnowledge.from_hash(
        @transport.request(:get, "/v1/Assistants/#{id}")
      )
    end

    def update(id, **kwargs)
      AssistantsV1Assistant.from_hash(
        @transport.request(:put, "/v1/Assistants/#{id}", json: build_json(UPDATE_FIELDS, kwargs))
      )
    end

    def delete(id)
      @transport.request(:delete, "/v1/Assistants/#{id}")
      nil
    end

    private

    def build_json(keys, kwargs)
      out = {}
      keys.each do |k|
        v = kwargs[k]
        next if v.nil?

        out[k.to_s] = v
      end
      out
    end
  end

  # ============================================================================
  # Per-Assistant scope — sub-resources under /v1/Assistants/{id}/...:
  #   - .tools        attach/detach + list
  #   - .knowledge    attach/detach + list
  #   - .feedbacks    list + create
  #   - .messages     create (send)
  # ============================================================================
  class AssistantsV1AssistantScope
    attr_reader :assistant_id

    def initialize(transport, assistant_id)
      @transport    = transport
      @assistant_id = assistant_id
    end

    def tools
      @tools ||= AssistantsV1AssistantToolsScope.new(@transport, @assistant_id)
    end

    def knowledge
      @knowledge ||= AssistantsV1AssistantKnowledgeScope.new(@transport, @assistant_id)
    end

    def feedbacks
      @feedbacks ||= AssistantsV1AssistantFeedbacksScope.new(@transport, @assistant_id)
    end

    def messages
      @messages ||= AssistantsV1AssistantMessagesScope.new(@transport, @assistant_id)
    end
  end

  # /v1/Assistants/{id}/Tools — list attached + attach/detach single Tool.
  class AssistantsV1AssistantToolsScope
    def initialize(transport, assistant_id)
      @transport    = transport
      @assistant_id = assistant_id
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      AssistantsV1ToolList.new(
        @transport.request(:get, "/v1/Assistants/#{@assistant_id}/Tools", params: params)
      )
    end

    # POST /v1/Assistants/{id}/Tools/{toolId} — 204 No Content on success.
    def attach(tool_id)
      @transport.request(:post, "/v1/Assistants/#{@assistant_id}/Tools/#{tool_id}")
      nil
    end

    # DELETE /v1/Assistants/{id}/Tools/{toolId} — 204 No Content on success.
    def detach(tool_id)
      @transport.request(:delete, "/v1/Assistants/#{@assistant_id}/Tools/#{tool_id}")
      nil
    end
  end

  # /v1/Assistants/{id}/Knowledge — list attached + attach/detach single Knowledge.
  class AssistantsV1AssistantKnowledgeScope
    def initialize(transport, assistant_id)
      @transport    = transport
      @assistant_id = assistant_id
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      AssistantsV1KnowledgeList.new(
        @transport.request(:get, "/v1/Assistants/#{@assistant_id}/Knowledge", params: params)
      )
    end

    # POST /v1/Assistants/{id}/Knowledge/{knowledgeId} — 204 No Content on success.
    def attach(knowledge_id)
      @transport.request(:post, "/v1/Assistants/#{@assistant_id}/Knowledge/#{knowledge_id}")
      nil
    end

    # DELETE /v1/Assistants/{id}/Knowledge/{knowledgeId} — 204 No Content on success.
    def detach(knowledge_id)
      @transport.request(:delete, "/v1/Assistants/#{@assistant_id}/Knowledge/#{knowledge_id}")
      nil
    end
  end

  # /v1/Assistants/{id}/Feedbacks — list + create.
  class AssistantsV1AssistantFeedbacksScope
    CREATE_FIELDS = %i[session_id message_id score text].freeze

    def initialize(transport, assistant_id)
      @transport    = transport
      @assistant_id = assistant_id
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      AssistantsV1FeedbackList.new(
        @transport.request(:get, "/v1/Assistants/#{@assistant_id}/Feedbacks", params: params)
      )
    end

    def create(session_id:, **kwargs)
      kwargs[:session_id] = session_id
      AssistantsV1Feedback.from_hash(
        @transport.request(:post, "/v1/Assistants/#{@assistant_id}/Feedbacks",
                           json: build_json(CREATE_FIELDS, kwargs))
      )
    end

    private

    def build_json(keys, kwargs)
      out = {}
      keys.each do |k|
        v = kwargs[k]
        next if v.nil?

        out[k.to_s] = v
      end
      out
    end
  end

  # /v1/Assistants/{id}/Messages — send (create) a message; returns the model's reply.
  class AssistantsV1AssistantMessagesScope
    CREATE_FIELDS = %i[identity body session_id webhook mode].freeze

    def initialize(transport, assistant_id)
      @transport    = transport
      @assistant_id = assistant_id
    end

    def create(identity:, body:, **kwargs)
      kwargs[:identity] = identity
      kwargs[:body]     = body
      AssistantsV1SendMessageResponse.from_hash(
        @transport.request(:post, "/v1/Assistants/#{@assistant_id}/Messages",
                           json: build_json(CREATE_FIELDS, kwargs))
      )
    end

    private

    def build_json(keys, kwargs)
      out = {}
      keys.each do |k|
        v = kwargs[k]
        next if v.nil?

        out[k.to_s] = v
      end
      out
    end
  end

  # ============================================================================
  # /v1/Tools — 5 CRUD ops on the top-level Tool resource.
  # `list` accepts an optional `assistant_id:` filter (wire name `AssistantId`).
  # Fetch returns the ToolWithPolicies shape (policies inline).
  # ============================================================================
  class AssistantsV1ToolsResource
    CREATE_FIELDS = %i[name type enabled assistant_id description meta].freeze
    UPDATE_FIELDS = %i[name type enabled description meta].freeze

    def initialize(transport)
      @transport = transport
    end

    def list(assistant_id: nil, page_size: nil)
      params = {}
      params['AssistantId'] = assistant_id unless assistant_id.nil?
      params['PageSize']    = page_size    unless page_size.nil?
      AssistantsV1ToolList.new(@transport.request(:get, '/v1/Tools', params: params))
    end

    def create(name:, type:, enabled:, **kwargs)
      kwargs[:name]    = name
      kwargs[:type]    = type
      kwargs[:enabled] = enabled
      AssistantsV1Tool.from_hash(
        @transport.request(:post, '/v1/Tools', json: build_json(CREATE_FIELDS, kwargs))
      )
    end

    def fetch(id)
      AssistantsV1ToolWithPolicies.from_hash(@transport.request(:get, "/v1/Tools/#{id}"))
    end

    def update(id, **kwargs)
      AssistantsV1Tool.from_hash(
        @transport.request(:put, "/v1/Tools/#{id}", json: build_json(UPDATE_FIELDS, kwargs))
      )
    end

    def delete(id)
      @transport.request(:delete, "/v1/Tools/#{id}")
      nil
    end

    private

    def build_json(keys, kwargs)
      out = {}
      keys.each do |k|
        v = kwargs[k]
        next if v.nil?

        out[k.to_s] = v
      end
      out
    end
  end

  # ============================================================================
  # /v1/Knowledge — 5 CRUD ops on the top-level Knowledge resource.
  # `list` accepts an optional `assistant_id:` filter (wire name `AssistantId`).
  # ============================================================================
  class AssistantsV1KnowledgeResource
    CREATE_FIELDS = %i[name type assistant_id description embedding_model knowledge_source_details].freeze
    UPDATE_FIELDS = %i[name type description embedding_model knowledge_source_details].freeze

    def initialize(transport)
      @transport = transport
    end

    def list(assistant_id: nil, page_size: nil)
      params = {}
      params['AssistantId'] = assistant_id unless assistant_id.nil?
      params['PageSize']    = page_size    unless page_size.nil?
      AssistantsV1KnowledgeList.new(@transport.request(:get, '/v1/Knowledge', params: params))
    end

    def create(name:, type:, **kwargs)
      kwargs[:name] = name
      kwargs[:type] = type
      AssistantsV1Knowledge.from_hash(
        @transport.request(:post, '/v1/Knowledge', json: build_json(CREATE_FIELDS, kwargs))
      )
    end

    def fetch(id)
      AssistantsV1Knowledge.from_hash(@transport.request(:get, "/v1/Knowledge/#{id}"))
    end

    def update(id, **kwargs)
      AssistantsV1Knowledge.from_hash(
        @transport.request(:put, "/v1/Knowledge/#{id}", json: build_json(UPDATE_FIELDS, kwargs))
      )
    end

    def delete(id)
      @transport.request(:delete, "/v1/Knowledge/#{id}")
      nil
    end

    private

    def build_json(keys, kwargs)
      out = {}
      keys.each do |k|
        v = kwargs[k]
        next if v.nil?

        out[k.to_s] = v
      end
      out
    end
  end

  # ============================================================================
  # Per-Knowledge scope — sub-resources under /v1/Knowledge/{id}/...:
  #   - .status   fetch ingestion status snapshot
  #   - .chunks   list indexed chunks
  # ============================================================================
  class AssistantsV1KnowledgeScope
    attr_reader :knowledge_id

    def initialize(transport, knowledge_id)
      @transport    = transport
      @knowledge_id = knowledge_id
    end

    def status
      @status ||= AssistantsV1KnowledgeStatusScope.new(@transport, @knowledge_id)
    end

    def chunks
      @chunks ||= AssistantsV1KnowledgeChunksScope.new(@transport, @knowledge_id)
    end
  end

  # /v1/Knowledge/{id}/Status — read-only ingestion status snapshot.
  class AssistantsV1KnowledgeStatusScope
    def initialize(transport, knowledge_id)
      @transport    = transport
      @knowledge_id = knowledge_id
    end

    def fetch
      AssistantsV1KnowledgeStatus.from_hash(
        @transport.request(:get, "/v1/Knowledge/#{@knowledge_id}/Status")
      )
    end
  end

  # /v1/Knowledge/{id}/Chunks — paged list of indexed chunks.
  class AssistantsV1KnowledgeChunksScope
    def initialize(transport, knowledge_id)
      @transport    = transport
      @knowledge_id = knowledge_id
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      AssistantsV1KnowledgeChunkList.new(
        @transport.request(:get, "/v1/Knowledge/#{@knowledge_id}/Chunks", params: params)
      )
    end
  end

  # ============================================================================
  # /v1/Sessions — list + fetch on the top-level Session resource.
  # ============================================================================
  class AssistantsV1SessionsResource
    def initialize(transport)
      @transport = transport
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      AssistantsV1SessionList.new(@transport.request(:get, '/v1/Sessions', params: params))
    end

    def fetch(id)
      AssistantsV1Session.from_hash(@transport.request(:get, "/v1/Sessions/#{id}"))
    end
  end

  # /v1/Sessions/{id}/Messages — list a session's messages.
  class AssistantsV1SessionScope
    attr_reader :session_id

    def initialize(transport, session_id)
      @transport  = transport
      @session_id = session_id
    end

    def messages
      @messages ||= AssistantsV1SessionMessagesScope.new(@transport, @session_id)
    end
  end

  class AssistantsV1SessionMessagesScope
    def initialize(transport, session_id)
      @transport  = transport
      @session_id = session_id
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      AssistantsV1MessageList.new(
        @transport.request(:get, "/v1/Sessions/#{@session_id}/Messages", params: params)
      )
    end
  end

  # ============================================================================
  # /v1/Policies — read-only list, filterable by ToolId/KnowledgeId.
  # ============================================================================
  class AssistantsV1PoliciesResource
    def initialize(transport)
      @transport = transport
    end

    def list(tool_id: nil, knowledge_id: nil, page_size: nil)
      params = {}
      params['ToolId']      = tool_id      unless tool_id.nil?
      params['KnowledgeId'] = knowledge_id unless knowledge_id.nil?
      params['PageSize']    = page_size    unless page_size.nil?
      AssistantsV1PolicyList.new(@transport.request(:get, '/v1/Policies', params: params))
    end
  end
end
