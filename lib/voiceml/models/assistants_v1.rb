# frozen_string_literal: true

require_relative 'common'
require_relative 'voice_v1' # V1Pageable lives here; Assistants v1 reuses the same `meta` envelope

module VoiceML
  # Assistants v1 (`/v1/Assistants`, `/v1/Tools`, `/v1/Knowledge`, `/v1/Sessions`,
  # `/v1/Policies`) — Twilio AI-Assistants surface. Same /v1 conventions as Voice v1
  # and Conversations v1: Basic-auth account resolution, ISO-8601 dates, `meta`
  # list envelope (V1Pageable). 7 families for v0.9.1:
  #   - Assistant (aia_asst_...)
  #   - Tool (aia_tool_...) + ToolWithPolicies fetch shape
  #   - Knowledge (aia_know_...) + KnowledgeStatus + KnowledgeChunk
  #   - Session
  #   - Message (aia_msg_...) + SendMessageResponse
  #   - Feedback (aia_fdbk_...)
  #   - Policy (aia_plcy_...)

  # AssistantsV1Assistant — `aia_asst_...`. Used by list/create/update/delete responses.
  class AssistantsV1Assistant
    ATTRIBUTES = %w[
      account_sid customer_ai id model name owner url personality_prompt
      date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class AssistantsV1AssistantList
    include V1Pageable
    attr_reader :assistants
    def initialize(hash = {})
      assign_meta_fields(hash)
      @assistants = (hash['assistants'] || []).map { |h| AssistantsV1Assistant.from_hash(h) }
    end
  end

  # AssistantsV1AssistantWithToolsAndKnowledge — fetch-one shape that includes the
  # attached tools and knowledge arrays inline.
  class AssistantsV1AssistantWithToolsAndKnowledge
    ATTRIBUTES = %w[
      account_sid customer_ai id model name owner url personality_prompt
      date_created date_updated tools knowledge
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # AssistantsV1Tool — `aia_tool_...`.
  class AssistantsV1Tool
    ATTRIBUTES = %w[
      account_sid description enabled id meta name requires_auth type url
      date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class AssistantsV1ToolList
    include V1Pageable
    attr_reader :tools
    def initialize(hash = {})
      assign_meta_fields(hash)
      @tools = (hash['tools'] || []).map { |h| AssistantsV1Tool.from_hash(h) }
    end
  end

  # AssistantsV1ToolWithPolicies — fetch-one shape that includes the policies array inline.
  class AssistantsV1ToolWithPolicies
    ATTRIBUTES = %w[
      account_sid description enabled id meta name requires_auth type url
      date_created date_updated policies
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # AssistantsV1Knowledge — `aia_know_...`.
  class AssistantsV1Knowledge
    ATTRIBUTES = %w[
      account_sid description id knowledge_source_details name status type url
      embedding_model date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class AssistantsV1KnowledgeList
    include V1Pageable
    attr_reader :knowledge
    def initialize(hash = {})
      assign_meta_fields(hash)
      @knowledge = (hash['knowledge'] || []).map { |h| AssistantsV1Knowledge.from_hash(h) }
    end
  end

  # AssistantsV1KnowledgeStatus — read-only ingestion status snapshot.
  class AssistantsV1KnowledgeStatus
    ATTRIBUTES = %w[account_sid status last_status date_updated].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # AssistantsV1KnowledgeChunk — single retrieved chunk of indexed Knowledge content.
  class AssistantsV1KnowledgeChunk
    ATTRIBUTES = %w[account_sid content metadata date_created date_updated].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class AssistantsV1KnowledgeChunkList
    include V1Pageable
    attr_reader :chunks
    def initialize(hash = {})
      assign_meta_fields(hash)
      @chunks = (hash['chunks'] || []).map { |h| AssistantsV1KnowledgeChunk.from_hash(h) }
    end
  end

  # AssistantsV1Session — a chat session between an identity and an Assistant.
  class AssistantsV1Session
    ATTRIBUTES = %w[
      id account_sid assistant_id verified identity date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class AssistantsV1SessionList
    include V1Pageable
    attr_reader :sessions
    def initialize(hash = {})
      assign_meta_fields(hash)
      @sessions = (hash['sessions'] || []).map { |h| AssistantsV1Session.from_hash(h) }
    end
  end

  # AssistantsV1Message — `aia_msg_...`. One message in an Assistant session.
  class AssistantsV1Message
    ATTRIBUTES = %w[
      id account_sid assistant_id session_id identity role content meta
      date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class AssistantsV1MessageList
    include V1Pageable
    attr_reader :messages
    def initialize(hash = {})
      assign_meta_fields(hash)
      @messages = (hash['messages'] || []).map { |h| AssistantsV1Message.from_hash(h) }
    end
  end

  # AssistantsV1SendMessageResponse — POST /v1/Assistants/{id}/Messages return shape.
  # Distinct from AssistantsV1Message: carries the model's reply body + flag/abort signals.
  class AssistantsV1SendMessageResponse
    ATTRIBUTES = %w[status flagged aborted session_id account_sid body error].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # AssistantsV1Feedback — `aia_fdbk_...`. Numeric score + text feedback on a message.
  class AssistantsV1Feedback
    ATTRIBUTES = %w[
      assistant_id id account_sid user_sid message_id score session_id text
      date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class AssistantsV1FeedbackList
    include V1Pageable
    attr_reader :feedbacks
    def initialize(hash = {})
      assign_meta_fields(hash)
      @feedbacks = (hash['feedbacks'] || []).map { |h| AssistantsV1Feedback.from_hash(h) }
    end
  end

  # AssistantsV1Policy — `aia_plcy_...`. Read-only — listed under /v1/Policies (filterable
  # by ToolId/KnowledgeId) and embedded inline on Tool fetch responses.
  class AssistantsV1Policy
    ATTRIBUTES = %w[
      id name description account_sid user_sid type policy_details
      date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs.key?(f) ? attrs[f] : attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class AssistantsV1PolicyList
    include V1Pageable
    attr_reader :policies
    def initialize(hash = {})
      assign_meta_fields(hash)
      @policies = (hash['policies'] || []).map { |h| AssistantsV1Policy.from_hash(h) }
    end
  end
end
