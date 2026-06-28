# frozen_string_literal: true

require_relative 'common'
require_relative 'voice_v1' # V1Pageable lives here; Conversations v1 reuses the same `meta` envelope

module VoiceML
  # Twilio Conversations v1 (conversations.twilio.com/v1) resources.
  #
  # Same /v1 conventions as Voice v1: Basic-auth account resolution, ISO-8601 dates,
  # `meta` list envelope (V1Pageable). 15 resources for v0.9.0:
  #   - Conversation (CH...), ConversationMessage (IM...), ConversationParticipant (MB...)
  #   - ConversationMessageReceipt (DY...), ConversationScopedWebhook (WH...)
  #   - Role (RL...), User (US...), Credential (CR...)
  #   - Configuration, ConfigurationWebhook, ConfigAddress (IG...)
  #   - ParticipantConversation, ConversationWithParticipants, UserConversation
  #   - Service (IS...) + ServiceConversation (CH..., service-scoped)

  # ConversationsV1Conversation — `CH...`.
  class ConversationsV1Conversation
    ATTRIBUTES = %w[
      account_sid chat_service_sid messaging_service_sid sid friendly_name
      unique_name attributes state date_created date_updated timers url links bindings
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ConversationList
    include V1Pageable
    attr_reader :conversations
    def initialize(hash = {})
      assign_meta_fields(hash)
      @conversations = (hash['conversations'] || []).map { |h| ConversationsV1Conversation.from_hash(h) }
    end
  end

  # ConversationsV1ConversationMessage — `IM...`.
  class ConversationsV1ConversationMessage
    ATTRIBUTES = %w[
      account_sid conversation_sid sid index author body media attributes
      participant_sid date_created date_updated url delivery links content_sid
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ConversationMessageList
    include V1Pageable
    attr_reader :messages
    def initialize(hash = {})
      assign_meta_fields(hash)
      @messages = (hash['messages'] || []).map { |h| ConversationsV1ConversationMessage.from_hash(h) }
    end
  end

  # ConversationsV1ConversationParticipant — `MB...`.
  class ConversationsV1ConversationParticipant
    ATTRIBUTES = %w[
      account_sid conversation_sid sid identity attributes messaging_binding
      role_sid date_created date_updated url last_read_message_index last_read_timestamp
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ConversationParticipantList
    include V1Pageable
    attr_reader :participants
    def initialize(hash = {})
      assign_meta_fields(hash)
      @participants = (hash['participants'] || []).map { |h| ConversationsV1ConversationParticipant.from_hash(h) }
    end
  end

  # ConversationsV1ConversationMessageReceipt — `DY...`.
  class ConversationsV1ConversationMessageReceipt
    ATTRIBUTES = %w[
      account_sid conversation_sid sid message_sid channel_message_sid
      participant_sid status error_code date_created date_updated url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ConversationMessageReceiptList
    include V1Pageable
    attr_reader :delivery_receipts
    def initialize(hash = {})
      assign_meta_fields(hash)
      @delivery_receipts = (hash['delivery_receipts'] || []).map { |h| ConversationsV1ConversationMessageReceipt.from_hash(h) }
    end
  end

  # ConversationsV1ConversationScopedWebhook — `WH...`.
  class ConversationsV1ConversationScopedWebhook
    ATTRIBUTES = %w[
      sid account_sid conversation_sid target url configuration date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ConversationScopedWebhookList
    include V1Pageable
    attr_reader :webhooks
    def initialize(hash = {})
      assign_meta_fields(hash)
      @webhooks = (hash['webhooks'] || []).map { |h| ConversationsV1ConversationScopedWebhook.from_hash(h) }
    end
  end

  # ConversationsV1Role — `RL...`.
  class ConversationsV1Role
    ATTRIBUTES = %w[
      sid account_sid chat_service_sid friendly_name type permissions
      date_created date_updated url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1RoleList
    include V1Pageable
    attr_reader :roles
    def initialize(hash = {})
      assign_meta_fields(hash)
      @roles = (hash['roles'] || []).map { |h| ConversationsV1Role.from_hash(h) }
    end
  end

  # ConversationsV1User — `US...`.
  class ConversationsV1User
    ATTRIBUTES = %w[
      sid account_sid chat_service_sid role_sid identity friendly_name attributes
      is_online is_notifiable date_created date_updated url links
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1UserList
    include V1Pageable
    attr_reader :users
    def initialize(hash = {})
      assign_meta_fields(hash)
      @users = (hash['users'] || []).map { |h| ConversationsV1User.from_hash(h) }
    end
  end

  # ConversationsV1Credential — `CR...` (push Credential — distinct from SipCredential).
  class ConversationsV1Credential
    ATTRIBUTES = %w[
      sid account_sid friendly_name type sandbox date_created date_updated url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1CredentialList
    include V1Pageable
    attr_reader :credentials
    def initialize(hash = {})
      assign_meta_fields(hash)
      @credentials = (hash['credentials'] || []).map { |h| ConversationsV1Credential.from_hash(h) }
    end
  end

  # ConversationsV1Configuration — account-level Conversations defaults.
  class ConversationsV1Configuration
    ATTRIBUTES = %w[
      account_sid default_chat_service_sid default_messaging_service_sid
      default_inactive_timer default_closed_timer url links
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # ConversationsV1ConfigurationWebhook — account-global webhook config.
  class ConversationsV1ConfigurationWebhook
    ATTRIBUTES = %w[
      account_sid method filters pre_webhook_url post_webhook_url target url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # ConversationsV1ConfigAddress — `IG...`.
  class ConversationsV1ConfigAddress
    ATTRIBUTES = %w[
      sid account_sid type address friendly_name auto_creation
      date_created date_updated url address_country
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ConfigAddressList
    include V1Pageable
    attr_reader :addresses
    def initialize(hash = {})
      assign_meta_fields(hash)
      @addresses = (hash['addresses'] || []).map { |h| ConversationsV1ConfigAddress.from_hash(h) }
    end
  end

  # ConversationsV1ParticipantConversation — read-only join of Participant + Conversation.
  class ConversationsV1ParticipantConversation
    ATTRIBUTES = %w[
      account_sid chat_service_sid participant_sid participant_user_sid
      participant_identity participant_messaging_binding conversation_sid
      conversation_unique_name conversation_friendly_name conversation_attributes
      conversation_date_created conversation_date_updated conversation_created_by
      conversation_state conversation_timers links
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ParticipantConversationList
    include V1Pageable
    attr_reader :conversations
    def initialize(hash = {})
      assign_meta_fields(hash)
      @conversations = (hash['conversations'] || []).map { |h| ConversationsV1ParticipantConversation.from_hash(h) }
    end
  end

  # ConversationsV1ConversationWithParticipants — single-call conversation + initial participants.
  # Returned by POST /v1/ConversationWithParticipants; field-identical to ConversationsV1Conversation.
  class ConversationsV1ConversationWithParticipants
    ATTRIBUTES = %w[
      account_sid chat_service_sid messaging_service_sid sid friendly_name
      unique_name attributes state date_created date_updated timers links bindings url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # ConversationsV1UserConversation — a user's view of a conversation they belong to.
  class ConversationsV1UserConversation
    ATTRIBUTES = %w[
      account_sid chat_service_sid conversation_sid unread_messages_count
      last_read_message_index participant_sid user_sid friendly_name conversation_state
      timers attributes date_created date_updated created_by notification_level
      unique_name url links
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1UserConversationList
    include V1Pageable
    attr_reader :conversations
    def initialize(hash = {})
      assign_meta_fields(hash)
      @conversations = (hash['conversations'] || []).map { |h| ConversationsV1UserConversation.from_hash(h) }
    end
  end

  # ConversationsV1Service — `IS...`. Conversation service.
  class ConversationsV1Service
    ATTRIBUTES = %w[
      sid account_sid friendly_name date_created date_updated url links
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceList
    include V1Pageable
    attr_reader :services
    def initialize(hash = {})
      assign_meta_fields(hash)
      @services = (hash['services'] || []).map { |h| ConversationsV1Service.from_hash(h) }
    end
  end

  # ConversationsV1ServiceConversation — service-scoped Conversation; field-identical to
  # ConversationsV1Conversation. Twilio's service_conversation mirrors conversation.
  class ConversationsV1ServiceConversation
    ATTRIBUTES = %w[
      account_sid chat_service_sid messaging_service_sid sid friendly_name
      unique_name attributes state date_created date_updated timers url links bindings
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceConversationList
    include V1Pageable
    attr_reader :conversations
    def initialize(hash = {})
      assign_meta_fields(hash)
      @conversations = (hash['conversations'] || []).map { |h| ConversationsV1ServiceConversation.from_hash(h) }
    end
  end

  # ============================================================================
  # Phase 4 — service-scoped sub-resources under /v1/Services/{ChatServiceSid}/.
  # Field-shape mirrors the account-level equivalents; `chat_service_sid` is
  # included on every record.
  # ============================================================================

  # ConversationsV1ServiceConversationMessage — `IM...`, scoped to a Service.
  class ConversationsV1ServiceConversationMessage
    ATTRIBUTES = %w[
      account_sid chat_service_sid conversation_sid sid index author body media
      attributes participant_sid date_created date_updated url delivery links content_sid
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceConversationMessageList
    include V1Pageable
    attr_reader :messages
    def initialize(hash = {})
      assign_meta_fields(hash)
      @messages = (hash['messages'] || []).map { |h| ConversationsV1ServiceConversationMessage.from_hash(h) }
    end
  end

  # ConversationsV1ServiceConversationParticipant — `MB...`, scoped to a Service.
  class ConversationsV1ServiceConversationParticipant
    ATTRIBUTES = %w[
      account_sid chat_service_sid conversation_sid sid identity attributes
      messaging_binding role_sid date_created date_updated url
      last_read_message_index last_read_timestamp
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceConversationParticipantList
    include V1Pageable
    attr_reader :participants
    def initialize(hash = {})
      assign_meta_fields(hash)
      @participants = (hash['participants'] || []).map { |h| ConversationsV1ServiceConversationParticipant.from_hash(h) }
    end
  end

  # ConversationsV1ServiceConversationMessageReceipt — `DY...`, scoped to a Service.
  class ConversationsV1ServiceConversationMessageReceipt
    ATTRIBUTES = %w[
      account_sid chat_service_sid conversation_sid sid message_sid
      channel_message_sid participant_sid status error_code
      date_created date_updated url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceConversationMessageReceiptList
    include V1Pageable
    attr_reader :delivery_receipts
    def initialize(hash = {})
      assign_meta_fields(hash)
      @delivery_receipts = (hash['delivery_receipts'] || []).map { |h| ConversationsV1ServiceConversationMessageReceipt.from_hash(h) }
    end
  end

  # ConversationsV1ServiceConversationScopedWebhook — `WH...`, scoped to a Service.
  class ConversationsV1ServiceConversationScopedWebhook
    ATTRIBUTES = %w[
      sid account_sid chat_service_sid conversation_sid target url configuration
      date_created date_updated
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceConversationScopedWebhookList
    include V1Pageable
    attr_reader :webhooks
    def initialize(hash = {})
      assign_meta_fields(hash)
      @webhooks = (hash['webhooks'] || []).map { |h| ConversationsV1ServiceConversationScopedWebhook.from_hash(h) }
    end
  end

  # ConversationsV1ServiceConversationWithParticipants — service-scoped
  # single-call conv + participants; field-identical to ServiceConversation.
  class ConversationsV1ServiceConversationWithParticipants
    ATTRIBUTES = %w[
      account_sid chat_service_sid messaging_service_sid sid friendly_name
      unique_name attributes state date_created date_updated timers links bindings url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # ConversationsV1ServiceParticipantConversation — read-only join, service-scoped.
  class ConversationsV1ServiceParticipantConversation
    ATTRIBUTES = %w[
      account_sid chat_service_sid participant_sid participant_user_sid
      participant_identity participant_messaging_binding conversation_sid
      conversation_unique_name conversation_friendly_name conversation_attributes
      conversation_date_created conversation_date_updated conversation_created_by
      conversation_state conversation_timers links
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceParticipantConversationList
    include V1Pageable
    attr_reader :conversations
    def initialize(hash = {})
      assign_meta_fields(hash)
      @conversations = (hash['conversations'] || []).map { |h| ConversationsV1ServiceParticipantConversation.from_hash(h) }
    end
  end

  # ConversationsV1ServiceUserConversation — a user's view of a service-scoped conversation.
  class ConversationsV1ServiceUserConversation
    ATTRIBUTES = %w[
      account_sid chat_service_sid conversation_sid unread_messages_count
      last_read_message_index participant_sid user_sid friendly_name
      conversation_state timers attributes date_created date_updated created_by
      notification_level unique_name url links
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceUserConversationList
    include V1Pageable
    attr_reader :conversations
    def initialize(hash = {})
      assign_meta_fields(hash)
      @conversations = (hash['conversations'] || []).map { |h| ConversationsV1ServiceUserConversation.from_hash(h) }
    end
  end

  # ConversationsV1ServiceRole — `RL...`, scoped to a Service.
  class ConversationsV1ServiceRole
    ATTRIBUTES = %w[
      sid account_sid chat_service_sid friendly_name type permissions
      date_created date_updated url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceRoleList
    include V1Pageable
    attr_reader :roles
    def initialize(hash = {})
      assign_meta_fields(hash)
      @roles = (hash['roles'] || []).map { |h| ConversationsV1ServiceRole.from_hash(h) }
    end
  end

  # ConversationsV1ServiceUser — `US...`, scoped to a Service.
  class ConversationsV1ServiceUser
    ATTRIBUTES = %w[
      sid account_sid chat_service_sid role_sid identity friendly_name attributes
      is_online is_notifiable date_created date_updated url links
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceUserList
    include V1Pageable
    attr_reader :users
    def initialize(hash = {})
      assign_meta_fields(hash)
      @users = (hash['users'] || []).map { |h| ConversationsV1ServiceUser.from_hash(h) }
    end
  end

  # ConversationsV1ServiceBinding — `BS...`, push-notification binding (read/delete only).
  class ConversationsV1ServiceBinding
    ATTRIBUTES = %w[
      sid account_sid chat_service_sid credential_sid date_created date_updated
      endpoint identity binding_type message_types url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class ConversationsV1ServiceBindingList
    include V1Pageable
    attr_reader :bindings
    def initialize(hash = {})
      assign_meta_fields(hash)
      @bindings = (hash['bindings'] || []).map { |h| ConversationsV1ServiceBinding.from_hash(h) }
    end
  end

  # ConversationsV1ServiceConfiguration — per-service singleton (fetch+update).
  class ConversationsV1ServiceConfiguration
    ATTRIBUTES = %w[
      chat_service_sid default_conversation_creator_role_sid
      default_conversation_role_sid default_chat_service_role_sid
      url links reachability_enabled
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # ConversationsV1ServiceNotification — per-service push-notification config singleton.
  class ConversationsV1ServiceNotification
    ATTRIBUTES = %w[
      account_sid chat_service_sid new_message added_to_conversation
      removed_from_conversation log_enabled url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # ConversationsV1ServiceWebhookConfiguration — per-service webhook config singleton.
  class ConversationsV1ServiceWebhookConfiguration
    ATTRIBUTES = %w[
      account_sid chat_service_sid pre_webhook_url post_webhook_url
      filters method url
    ].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end
end
