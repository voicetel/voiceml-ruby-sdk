# frozen_string_literal: true

require_relative '../models/conversations_v1'

module VoiceML
  # `client.conversations_v1` — Twilio Conversations v1 (conversations.twilio.com/v1).
  # Sits outside the /2010-04-01/Accounts/... namespace; account resolved from Basic auth.
  class ConversationsV1Resource
    attr_reader :conversations, :roles, :users, :credentials, :configuration,
                :participant_conversations, :conversation_with_participants,
                :services

    def initialize(transport)
      @conversations                  = ConversationsV1ConversationsResource.new(transport)
      @roles                          = ConversationsV1RolesResource.new(transport)
      @users                          = ConversationsV1UsersResource.new(transport)
      @credentials                    = ConversationsV1CredentialsResource.new(transport)
      @configuration                  = ConversationsV1ConfigurationResource.new(transport)
      @participant_conversations      = ConversationsV1ParticipantConversationsResource.new(transport)
      @conversation_with_participants = ConversationsV1ConversationWithParticipantsResource.new(transport)
      @services                       = ConversationsV1ServicesResource.new(transport)
    end
  end

  # ============================================================================
  # /v1/Conversations and all nested sub-resources (messages, participants,
  # webhooks, message receipts).
  # ============================================================================
  class ConversationsV1ConversationsResource
    CONVERSATION_FIELDS = {
      'FriendlyName' => :friendly_name,
      'UniqueName' => :unique_name,
      'MessagingServiceSid' => :messaging_service_sid,
      'Attributes' => :attributes,
      'State' => :state,
      'Timers.Inactive' => :timers_inactive,
      'Timers.Closed' => :timers_closed,
      'Bindings.Email.Address' => :bindings_email_address,
      'Bindings.Email.Name' => :bindings_email_name
    }.freeze

    UPDATE_FIELDS = {
      'FriendlyName' => :friendly_name,
      'UniqueName' => :unique_name,
      'MessagingServiceSid' => :messaging_service_sid,
      'Attributes' => :attributes,
      'State' => :state,
      'Timers.Inactive' => :timers_inactive,
      'Timers.Closed' => :timers_closed
    }.freeze

    MESSAGE_FIELDS = {
      'Author' => :author,
      'Body' => :body,
      'Attributes' => :attributes,
      'ContentSid' => :content_sid
    }.freeze

    MESSAGE_UPDATE_FIELDS = {
      'Author' => :author,
      'Body' => :body,
      'Attributes' => :attributes
    }.freeze

    PARTICIPANT_FIELDS = {
      'Identity' => :identity,
      'Attributes' => :attributes,
      'RoleSid' => :role_sid,
      'MessagingBinding.Address' => :messaging_binding_address,
      'MessagingBinding.ProxyAddress' => :messaging_binding_proxy_address,
      'MessagingBinding.ProjectedAddress' => :messaging_binding_projected_address
    }.freeze

    PARTICIPANT_UPDATE_FIELDS = {
      'Identity' => :identity,
      'Attributes' => :attributes,
      'RoleSid' => :role_sid,
      'LastReadMessageIndex' => :last_read_message_index,
      'LastReadTimestamp' => :last_read_timestamp
    }.freeze

    WEBHOOK_FIELDS = {
      'Target' => :target,
      'Configuration.Url' => :configuration_url,
      'Configuration.Method' => :configuration_method,
      'Configuration.FlowSid' => :configuration_flow_sid,
      'Configuration.ReplayAfter' => :configuration_replay_after
    }.freeze

    WEBHOOK_UPDATE_FIELDS = {
      'Configuration.Url' => :configuration_url,
      'Configuration.Method' => :configuration_method,
      'Configuration.FlowSid' => :configuration_flow_sid
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    # --- Conversations ---
    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ConversationList.new(@transport.request(:get, '/v1/Conversations', params: params))
    end

    def create(**kwargs)
      ConversationsV1Conversation.from_hash(
        @transport.request(:post, '/v1/Conversations', form: build_form(CONVERSATION_FIELDS, kwargs))
      )
    end

    def fetch(sid)
      ConversationsV1Conversation.from_hash(@transport.request(:get, "/v1/Conversations/#{sid}"))
    end

    def update(sid, **kwargs)
      ConversationsV1Conversation.from_hash(
        @transport.request(:post, "/v1/Conversations/#{sid}", form: build_form(UPDATE_FIELDS, kwargs))
      )
    end

    def delete(sid)
      @transport.request(:delete, "/v1/Conversations/#{sid}")
      nil
    end

    # --- Messages ---
    def list_messages(conversation_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ConversationMessageList.new(
        @transport.request(:get, "/v1/Conversations/#{conversation_sid}/Messages", params: params)
      )
    end

    def create_message(conversation_sid, **kwargs)
      ConversationsV1ConversationMessage.from_hash(
        @transport.request(:post, "/v1/Conversations/#{conversation_sid}/Messages",
                           form: build_form(MESSAGE_FIELDS, kwargs))
      )
    end

    def fetch_message(conversation_sid, message_sid)
      ConversationsV1ConversationMessage.from_hash(
        @transport.request(:get, "/v1/Conversations/#{conversation_sid}/Messages/#{message_sid}")
      )
    end

    def update_message(conversation_sid, message_sid, **kwargs)
      ConversationsV1ConversationMessage.from_hash(
        @transport.request(:post, "/v1/Conversations/#{conversation_sid}/Messages/#{message_sid}",
                           form: build_form(MESSAGE_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_message(conversation_sid, message_sid)
      @transport.request(:delete, "/v1/Conversations/#{conversation_sid}/Messages/#{message_sid}")
      nil
    end

    # --- Message Receipts (read-only) ---
    def list_message_receipts(conversation_sid, message_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ConversationMessageReceiptList.new(
        @transport.request(:get, "/v1/Conversations/#{conversation_sid}/Messages/#{message_sid}/Receipts",
                           params: params)
      )
    end

    def fetch_message_receipt(conversation_sid, message_sid, sid)
      ConversationsV1ConversationMessageReceipt.from_hash(
        @transport.request(:get, "/v1/Conversations/#{conversation_sid}/Messages/#{message_sid}/Receipts/#{sid}")
      )
    end

    # --- Participants ---
    def list_participants(conversation_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ConversationParticipantList.new(
        @transport.request(:get, "/v1/Conversations/#{conversation_sid}/Participants", params: params)
      )
    end

    def create_participant(conversation_sid, **kwargs)
      ConversationsV1ConversationParticipant.from_hash(
        @transport.request(:post, "/v1/Conversations/#{conversation_sid}/Participants",
                           form: build_form(PARTICIPANT_FIELDS, kwargs))
      )
    end

    def fetch_participant(conversation_sid, participant_sid)
      ConversationsV1ConversationParticipant.from_hash(
        @transport.request(:get, "/v1/Conversations/#{conversation_sid}/Participants/#{participant_sid}")
      )
    end

    def update_participant(conversation_sid, participant_sid, **kwargs)
      ConversationsV1ConversationParticipant.from_hash(
        @transport.request(:post, "/v1/Conversations/#{conversation_sid}/Participants/#{participant_sid}",
                           form: build_form(PARTICIPANT_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_participant(conversation_sid, participant_sid)
      @transport.request(:delete, "/v1/Conversations/#{conversation_sid}/Participants/#{participant_sid}")
      nil
    end

    # --- Scoped Webhooks ---
    def list_webhooks(conversation_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ConversationScopedWebhookList.new(
        @transport.request(:get, "/v1/Conversations/#{conversation_sid}/Webhooks", params: params)
      )
    end

    def create_webhook(conversation_sid, target:, **kwargs)
      kwargs[:target] = target
      ConversationsV1ConversationScopedWebhook.from_hash(
        @transport.request(:post, "/v1/Conversations/#{conversation_sid}/Webhooks",
                           form: build_form(WEBHOOK_FIELDS, kwargs))
      )
    end

    def fetch_webhook(conversation_sid, webhook_sid)
      ConversationsV1ConversationScopedWebhook.from_hash(
        @transport.request(:get, "/v1/Conversations/#{conversation_sid}/Webhooks/#{webhook_sid}")
      )
    end

    def update_webhook(conversation_sid, webhook_sid, **kwargs)
      ConversationsV1ConversationScopedWebhook.from_hash(
        @transport.request(:post, "/v1/Conversations/#{conversation_sid}/Webhooks/#{webhook_sid}",
                           form: build_form(WEBHOOK_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_webhook(conversation_sid, webhook_sid)
      @transport.request(:delete, "/v1/Conversations/#{conversation_sid}/Webhooks/#{webhook_sid}")
      nil
    end

    private

    def build_form(map, kwargs)
      out = {}
      map.each do |wire, k|
        value = kwargs[k]
        next if value.nil?

        out[wire] = value
      end
      out
    end
  end

  # ============================================================================
  # /v1/Roles
  # ============================================================================
  class ConversationsV1RolesResource
    def initialize(transport)
      @transport = transport
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1RoleList.new(@transport.request(:get, '/v1/Roles', params: params))
    end

    def create(friendly_name:, type:, permission:)
      form = { 'FriendlyName' => friendly_name, 'Type' => type, 'Permission' => Array(permission) }
      ConversationsV1Role.from_hash(@transport.request(:post, '/v1/Roles', form: form))
    end

    def fetch(sid)
      ConversationsV1Role.from_hash(@transport.request(:get, "/v1/Roles/#{sid}"))
    end

    def update(sid, permission:)
      form = { 'Permission' => Array(permission) }
      ConversationsV1Role.from_hash(@transport.request(:post, "/v1/Roles/#{sid}", form: form))
    end

    def delete(sid)
      @transport.request(:delete, "/v1/Roles/#{sid}")
      nil
    end
  end

  # ============================================================================
  # /v1/Users + nested /v1/Users/{Sid}/Conversations (UserConversation)
  # ============================================================================
  class ConversationsV1UsersResource
    USER_FIELDS = {
      'Identity' => :identity,
      'FriendlyName' => :friendly_name,
      'Attributes' => :attributes,
      'RoleSid' => :role_sid
    }.freeze

    USER_UPDATE_FIELDS = {
      'FriendlyName' => :friendly_name,
      'Attributes' => :attributes,
      'RoleSid' => :role_sid
    }.freeze

    USER_CONVERSATION_UPDATE_FIELDS = {
      'NotificationLevel' => :notification_level,
      'LastReadMessageIndex' => :last_read_message_index,
      'LastReadTimestamp' => :last_read_timestamp
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1UserList.new(@transport.request(:get, '/v1/Users', params: params))
    end

    def create(identity:, friendly_name: nil, attributes: nil, role_sid: nil)
      kwargs = { identity: identity, friendly_name: friendly_name, attributes: attributes, role_sid: role_sid }
      ConversationsV1User.from_hash(@transport.request(:post, '/v1/Users', form: build_form(USER_FIELDS, kwargs)))
    end

    def fetch(sid)
      ConversationsV1User.from_hash(@transport.request(:get, "/v1/Users/#{sid}"))
    end

    def update(sid, **kwargs)
      ConversationsV1User.from_hash(
        @transport.request(:post, "/v1/Users/#{sid}", form: build_form(USER_UPDATE_FIELDS, kwargs))
      )
    end

    def delete(sid)
      @transport.request(:delete, "/v1/Users/#{sid}")
      nil
    end

    # --- /v1/Users/{Sid}/Conversations ---
    def list_user_conversations(user_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1UserConversationList.new(
        @transport.request(:get, "/v1/Users/#{user_sid}/Conversations", params: params)
      )
    end

    def fetch_user_conversation(user_sid, conversation_sid)
      ConversationsV1UserConversation.from_hash(
        @transport.request(:get, "/v1/Users/#{user_sid}/Conversations/#{conversation_sid}")
      )
    end

    def update_user_conversation(user_sid, conversation_sid, **kwargs)
      ConversationsV1UserConversation.from_hash(
        @transport.request(:post, "/v1/Users/#{user_sid}/Conversations/#{conversation_sid}",
                           form: build_form(USER_CONVERSATION_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_user_conversation(user_sid, conversation_sid)
      @transport.request(:delete, "/v1/Users/#{user_sid}/Conversations/#{conversation_sid}")
      nil
    end

    private

    def build_form(map, kwargs)
      out = {}
      map.each do |wire, k|
        value = kwargs[k]
        next if value.nil?

        out[wire] = value
      end
      out
    end
  end

  # ============================================================================
  # /v1/Credentials (push credentials — distinct from /SIP/Credentials)
  # ============================================================================
  class ConversationsV1CredentialsResource
    CREDENTIAL_FIELDS = {
      'Type' => :type,
      'FriendlyName' => :friendly_name,
      'Certificate' => :certificate,
      'PrivateKey' => :private_key,
      'Sandbox' => :sandbox,
      'ApiKey' => :api_key,
      'Secret' => :secret
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1CredentialList.new(@transport.request(:get, '/v1/Credentials', params: params))
    end

    def create(type:, **kwargs)
      kwargs[:type] = type
      ConversationsV1Credential.from_hash(
        @transport.request(:post, '/v1/Credentials', form: build_form(kwargs))
      )
    end

    def fetch(sid)
      ConversationsV1Credential.from_hash(@transport.request(:get, "/v1/Credentials/#{sid}"))
    end

    def update(sid, **kwargs)
      ConversationsV1Credential.from_hash(
        @transport.request(:post, "/v1/Credentials/#{sid}", form: build_form(kwargs))
      )
    end

    def delete(sid)
      @transport.request(:delete, "/v1/Credentials/#{sid}")
      nil
    end

    private

    def build_form(kwargs)
      out = {}
      CREDENTIAL_FIELDS.each do |wire, k|
        value = kwargs[k]
        next if value.nil?

        out[wire] = value
      end
      out
    end
  end

  # ============================================================================
  # /v1/Configuration (singleton) + nested /Webhooks (singleton) + /Addresses (CRUD)
  # ============================================================================
  class ConversationsV1ConfigurationResource
    CONFIG_FIELDS = {
      'DefaultChatServiceSid' => :default_chat_service_sid,
      'DefaultMessagingServiceSid' => :default_messaging_service_sid,
      'DefaultInactiveTimer' => :default_inactive_timer,
      'DefaultClosedTimer' => :default_closed_timer
    }.freeze

    WEBHOOK_FIELDS = {
      'Method' => :method,
      'Filters' => :filters,
      'PreWebhookUrl' => :pre_webhook_url,
      'PostWebhookUrl' => :post_webhook_url,
      'Target' => :target
    }.freeze

    ADDRESS_FIELDS = {
      'Type' => :type,
      'Address' => :address,
      'FriendlyName' => :friendly_name,
      'AutoCreation.Enabled' => :auto_creation_enabled,
      'AutoCreation.Type' => :auto_creation_type,
      'AutoCreation.WebhookUrl' => :auto_creation_webhook_url,
      'AddressCountry' => :address_country
    }.freeze

    ADDRESS_UPDATE_FIELDS = {
      'FriendlyName' => :friendly_name,
      'AutoCreation.Enabled' => :auto_creation_enabled,
      'AutoCreation.Type' => :auto_creation_type,
      'AutoCreation.WebhookUrl' => :auto_creation_webhook_url
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    # --- Configuration singleton ---
    def fetch
      ConversationsV1Configuration.from_hash(@transport.request(:get, '/v1/Configuration'))
    end

    def update(**kwargs)
      ConversationsV1Configuration.from_hash(
        @transport.request(:post, '/v1/Configuration', form: build_form(CONFIG_FIELDS, kwargs))
      )
    end

    # --- Webhooks singleton ---
    def fetch_webhooks
      ConversationsV1ConfigurationWebhook.from_hash(@transport.request(:get, '/v1/Configuration/Webhooks'))
    end

    def update_webhooks(**kwargs)
      ConversationsV1ConfigurationWebhook.from_hash(
        @transport.request(:post, '/v1/Configuration/Webhooks', form: build_form(WEBHOOK_FIELDS, kwargs))
      )
    end

    # --- Addresses CRUD ---
    def list_addresses(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ConfigAddressList.new(
        @transport.request(:get, '/v1/Configuration/Addresses', params: params)
      )
    end

    def create_address(type:, address:, **kwargs)
      kwargs[:type] = type
      kwargs[:address] = address
      ConversationsV1ConfigAddress.from_hash(
        @transport.request(:post, '/v1/Configuration/Addresses', form: build_form(ADDRESS_FIELDS, kwargs))
      )
    end

    def fetch_address(sid)
      ConversationsV1ConfigAddress.from_hash(@transport.request(:get, "/v1/Configuration/Addresses/#{sid}"))
    end

    def update_address(sid, **kwargs)
      ConversationsV1ConfigAddress.from_hash(
        @transport.request(:post, "/v1/Configuration/Addresses/#{sid}", form: build_form(ADDRESS_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_address(sid)
      @transport.request(:delete, "/v1/Configuration/Addresses/#{sid}")
      nil
    end

    private

    def build_form(map, kwargs)
      out = {}
      map.each do |wire, k|
        value = kwargs[k]
        next if value.nil?

        out[wire] = value
      end
      out
    end
  end

  # ============================================================================
  # /v1/ParticipantConversations (read-only list)
  # ============================================================================
  class ConversationsV1ParticipantConversationsResource
    def initialize(transport)
      @transport = transport
    end

    def list(identity: nil, address: nil, page_size: nil)
      params = {}
      params['Identity'] = identity unless identity.nil?
      params['Address']  = address unless address.nil?
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ParticipantConversationList.new(
        @transport.request(:get, '/v1/ParticipantConversations', params: params)
      )
    end
  end

  # ============================================================================
  # /v1/ConversationWithParticipants (single-call conv + participants)
  # ============================================================================
  class ConversationsV1ConversationWithParticipantsResource
    FIELDS = {
      'FriendlyName' => :friendly_name,
      'UniqueName' => :unique_name,
      'MessagingServiceSid' => :messaging_service_sid,
      'Attributes' => :attributes,
      'State' => :state,
      'Timers.Inactive' => :timers_inactive,
      'Timers.Closed' => :timers_closed,
      'Participant' => :participant
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    def create(participant: nil, **kwargs)
      kwargs[:participant] = participant unless participant.nil?
      form = {}
      FIELDS.each do |wire, k|
        value = kwargs[k]
        next if value.nil?

        form[wire] = value
      end
      ConversationsV1ConversationWithParticipants.from_hash(
        @transport.request(:post, '/v1/ConversationWithParticipants', form: form)
      )
    end
  end

  # ============================================================================
  # /v1/Services + nested /Conversations
  # ============================================================================
  class ConversationsV1ServicesResource
    SERVICE_CONVERSATION_FIELDS = {
      'FriendlyName' => :friendly_name,
      'UniqueName' => :unique_name,
      'MessagingServiceSid' => :messaging_service_sid,
      'Attributes' => :attributes,
      'State' => :state,
      'Timers.Inactive' => :timers_inactive,
      'Timers.Closed' => :timers_closed
    }.freeze

    SERVICE_CONVERSATION_UPDATE_FIELDS = {
      'FriendlyName' => :friendly_name,
      'UniqueName' => :unique_name,
      'Attributes' => :attributes,
      'State' => :state,
      'Timers.Inactive' => :timers_inactive,
      'Timers.Closed' => :timers_closed
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceList.new(@transport.request(:get, '/v1/Services', params: params))
    end

    def create(friendly_name:)
      ConversationsV1Service.from_hash(
        @transport.request(:post, '/v1/Services', form: { 'FriendlyName' => friendly_name })
      )
    end

    def fetch(chat_service_sid)
      ConversationsV1Service.from_hash(@transport.request(:get, "/v1/Services/#{chat_service_sid}"))
    end

    def delete(chat_service_sid)
      @transport.request(:delete, "/v1/Services/#{chat_service_sid}")
      nil
    end

    # --- /v1/Services/{ChatServiceSid}/Conversations ---
    def list_conversations(chat_service_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceConversationList.new(
        @transport.request(:get, "/v1/Services/#{chat_service_sid}/Conversations", params: params)
      )
    end

    def create_conversation(chat_service_sid, **kwargs)
      ConversationsV1ServiceConversation.from_hash(
        @transport.request(:post, "/v1/Services/#{chat_service_sid}/Conversations",
                           form: build_form(SERVICE_CONVERSATION_FIELDS, kwargs))
      )
    end

    def fetch_conversation(chat_service_sid, conversation_sid)
      ConversationsV1ServiceConversation.from_hash(
        @transport.request(:get, "/v1/Services/#{chat_service_sid}/Conversations/#{conversation_sid}")
      )
    end

    def update_conversation(chat_service_sid, conversation_sid, **kwargs)
      ConversationsV1ServiceConversation.from_hash(
        @transport.request(:post, "/v1/Services/#{chat_service_sid}/Conversations/#{conversation_sid}",
                           form: build_form(SERVICE_CONVERSATION_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_conversation(chat_service_sid, conversation_sid)
      @transport.request(:delete, "/v1/Services/#{chat_service_sid}/Conversations/#{conversation_sid}")
      nil
    end

    # Returns a scope object exposing the 48 Phase-4 sub-resource ops under
    # `/v1/Services/{chat_service_sid}/...`. The scope binds `chat_service_sid`
    # once so callers don't need to thread it through each call.
    def scope(chat_service_sid)
      ConversationsV1ServiceScopeResource.new(@transport, chat_service_sid)
    end

    private

    def build_form(map, kwargs)
      out = {}
      map.each do |wire, k|
        value = kwargs[k]
        next if value.nil?

        out[wire] = value
      end
      out
    end
  end

  # ============================================================================
  # Phase 4 — /v1/Services/{ChatServiceSid}/... — 15 sub-resource families,
  # 48 ops. Scoped via `client.conversations_v1.services.scope(IS_sid)`.
  # Flat method style matches the rest of conversations_v1.
  # ============================================================================
  class ConversationsV1ServiceScopeResource
    CONVERSATION_FIELDS = {
      'FriendlyName' => :friendly_name,
      'UniqueName' => :unique_name,
      'MessagingServiceSid' => :messaging_service_sid,
      'Attributes' => :attributes,
      'State' => :state,
      'Timers.Inactive' => :timers_inactive,
      'Timers.Closed' => :timers_closed
    }.freeze

    CONVERSATION_UPDATE_FIELDS = {
      'FriendlyName' => :friendly_name,
      'UniqueName' => :unique_name,
      'Attributes' => :attributes,
      'State' => :state,
      'Timers.Inactive' => :timers_inactive,
      'Timers.Closed' => :timers_closed
    }.freeze

    MESSAGE_FIELDS = {
      'Author' => :author,
      'Body' => :body,
      'Attributes' => :attributes,
      'ContentSid' => :content_sid
    }.freeze

    MESSAGE_UPDATE_FIELDS = {
      'Author' => :author,
      'Body' => :body,
      'Attributes' => :attributes
    }.freeze

    PARTICIPANT_FIELDS = {
      'Identity' => :identity,
      'Attributes' => :attributes,
      'RoleSid' => :role_sid,
      'MessagingBinding.Address' => :messaging_binding_address,
      'MessagingBinding.ProxyAddress' => :messaging_binding_proxy_address,
      'MessagingBinding.ProjectedAddress' => :messaging_binding_projected_address
    }.freeze

    PARTICIPANT_UPDATE_FIELDS = {
      'Attributes' => :attributes,
      'RoleSid' => :role_sid
    }.freeze

    WEBHOOK_FIELDS = {
      'Target' => :target,
      'Configuration.Url' => :configuration_url,
      'Configuration.Method' => :configuration_method,
      'Configuration.FlowSid' => :configuration_flow_sid
    }.freeze

    WEBHOOK_UPDATE_FIELDS = {
      'Configuration.Url' => :configuration_url,
      'Configuration.Method' => :configuration_method,
      'Configuration.FlowSid' => :configuration_flow_sid
    }.freeze

    USER_FIELDS = {
      'Identity' => :identity,
      'FriendlyName' => :friendly_name,
      'Attributes' => :attributes,
      'RoleSid' => :role_sid
    }.freeze

    USER_UPDATE_FIELDS = {
      'FriendlyName' => :friendly_name,
      'Attributes' => :attributes,
      'RoleSid' => :role_sid
    }.freeze

    CONV_WITH_PARTICIPANTS_FIELDS = {
      'FriendlyName' => :friendly_name,
      'UniqueName' => :unique_name,
      'MessagingServiceSid' => :messaging_service_sid,
      'Attributes' => :attributes,
      'State' => :state,
      'Timers.Inactive' => :timers_inactive,
      'Timers.Closed' => :timers_closed,
      'Participant' => :participant
    }.freeze

    CONFIG_UPDATE_FIELDS = {
      'DefaultChatServiceRoleSid' => :default_chat_service_role_sid,
      'DefaultConversationCreatorRoleSid' => :default_conversation_creator_role_sid,
      'DefaultConversationRoleSid' => :default_conversation_role_sid,
      'ReachabilityEnabled' => :reachability_enabled
    }.freeze

    NOTIFICATION_UPDATE_FIELDS = {
      'LogEnabled' => :log_enabled,
      'NewMessage.Enabled' => :new_message_enabled,
      'NewMessage.Template' => :new_message_template,
      'NewMessage.Sound' => :new_message_sound,
      'NewMessage.BadgeCountEnabled' => :new_message_badge_count_enabled,
      'NewMessage.WithMedia.Enabled' => :new_message_with_media_enabled,
      'NewMessage.WithMedia.Template' => :new_message_with_media_template,
      'AddedToConversation.Enabled' => :added_to_conversation_enabled,
      'AddedToConversation.Template' => :added_to_conversation_template,
      'AddedToConversation.Sound' => :added_to_conversation_sound,
      'RemovedFromConversation.Enabled' => :removed_from_conversation_enabled,
      'RemovedFromConversation.Template' => :removed_from_conversation_template,
      'RemovedFromConversation.Sound' => :removed_from_conversation_sound
    }.freeze

    WEBHOOK_CONFIG_UPDATE_FIELDS = {
      'PreWebhookUrl' => :pre_webhook_url,
      'PostWebhookUrl' => :post_webhook_url,
      'Method' => :method,
      'Filters' => :filters
    }.freeze

    attr_reader :chat_service_sid

    def initialize(transport, chat_service_sid)
      @transport = transport
      @chat_service_sid = chat_service_sid
    end

    # --- ServiceConversation (5 CRUD) ---
    def list_conversations(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceConversationList.new(
        @transport.request(:get, conv_root, params: params)
      )
    end

    def create_conversation(**kwargs)
      ConversationsV1ServiceConversation.from_hash(
        @transport.request(:post, conv_root, form: build_form(CONVERSATION_FIELDS, kwargs))
      )
    end

    def fetch_conversation(conversation_sid)
      ConversationsV1ServiceConversation.from_hash(
        @transport.request(:get, "#{conv_root}/#{conversation_sid}")
      )
    end

    def update_conversation(conversation_sid, **kwargs)
      ConversationsV1ServiceConversation.from_hash(
        @transport.request(:post, "#{conv_root}/#{conversation_sid}",
                           form: build_form(CONVERSATION_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_conversation(conversation_sid)
      @transport.request(:delete, "#{conv_root}/#{conversation_sid}")
      nil
    end

    # --- ServiceConversationMessage (5 CRUD) ---
    def list_messages(conversation_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceConversationMessageList.new(
        @transport.request(:get, "#{conv_root}/#{conversation_sid}/Messages", params: params)
      )
    end

    def create_message(conversation_sid, **kwargs)
      ConversationsV1ServiceConversationMessage.from_hash(
        @transport.request(:post, "#{conv_root}/#{conversation_sid}/Messages",
                           form: build_form(MESSAGE_FIELDS, kwargs))
      )
    end

    def fetch_message(conversation_sid, message_sid)
      ConversationsV1ServiceConversationMessage.from_hash(
        @transport.request(:get, "#{conv_root}/#{conversation_sid}/Messages/#{message_sid}")
      )
    end

    def update_message(conversation_sid, message_sid, **kwargs)
      ConversationsV1ServiceConversationMessage.from_hash(
        @transport.request(:post, "#{conv_root}/#{conversation_sid}/Messages/#{message_sid}",
                           form: build_form(MESSAGE_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_message(conversation_sid, message_sid)
      @transport.request(:delete, "#{conv_root}/#{conversation_sid}/Messages/#{message_sid}")
      nil
    end

    # --- ServiceConversationMessageReceipt (list+fetch only) ---
    def list_message_receipts(conversation_sid, message_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceConversationMessageReceiptList.new(
        @transport.request(:get,
                           "#{conv_root}/#{conversation_sid}/Messages/#{message_sid}/Receipts",
                           params: params)
      )
    end

    def fetch_message_receipt(conversation_sid, message_sid, sid)
      ConversationsV1ServiceConversationMessageReceipt.from_hash(
        @transport.request(:get,
                           "#{conv_root}/#{conversation_sid}/Messages/#{message_sid}/Receipts/#{sid}")
      )
    end

    # --- ServiceConversationParticipant (5 CRUD) ---
    def list_participants(conversation_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceConversationParticipantList.new(
        @transport.request(:get, "#{conv_root}/#{conversation_sid}/Participants", params: params)
      )
    end

    def create_participant(conversation_sid, **kwargs)
      ConversationsV1ServiceConversationParticipant.from_hash(
        @transport.request(:post, "#{conv_root}/#{conversation_sid}/Participants",
                           form: build_form(PARTICIPANT_FIELDS, kwargs))
      )
    end

    def fetch_participant(conversation_sid, participant_sid)
      ConversationsV1ServiceConversationParticipant.from_hash(
        @transport.request(:get, "#{conv_root}/#{conversation_sid}/Participants/#{participant_sid}")
      )
    end

    def update_participant(conversation_sid, participant_sid, **kwargs)
      ConversationsV1ServiceConversationParticipant.from_hash(
        @transport.request(:post, "#{conv_root}/#{conversation_sid}/Participants/#{participant_sid}",
                           form: build_form(PARTICIPANT_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_participant(conversation_sid, participant_sid)
      @transport.request(:delete, "#{conv_root}/#{conversation_sid}/Participants/#{participant_sid}")
      nil
    end

    # --- ServiceConversationScopedWebhook (5 CRUD) ---
    def list_webhooks(conversation_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceConversationScopedWebhookList.new(
        @transport.request(:get, "#{conv_root}/#{conversation_sid}/Webhooks", params: params)
      )
    end

    def create_webhook(conversation_sid, target:, **kwargs)
      kwargs[:target] = target
      ConversationsV1ServiceConversationScopedWebhook.from_hash(
        @transport.request(:post, "#{conv_root}/#{conversation_sid}/Webhooks",
                           form: build_form(WEBHOOK_FIELDS, kwargs))
      )
    end

    def fetch_webhook(conversation_sid, webhook_sid)
      ConversationsV1ServiceConversationScopedWebhook.from_hash(
        @transport.request(:get, "#{conv_root}/#{conversation_sid}/Webhooks/#{webhook_sid}")
      )
    end

    def update_webhook(conversation_sid, webhook_sid, **kwargs)
      ConversationsV1ServiceConversationScopedWebhook.from_hash(
        @transport.request(:post, "#{conv_root}/#{conversation_sid}/Webhooks/#{webhook_sid}",
                           form: build_form(WEBHOOK_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_webhook(conversation_sid, webhook_sid)
      @transport.request(:delete, "#{conv_root}/#{conversation_sid}/Webhooks/#{webhook_sid}")
      nil
    end

    # --- ServiceConversationWithParticipants (create only) ---
    def create_conversation_with_participants(**kwargs)
      ConversationsV1ServiceConversationWithParticipants.from_hash(
        @transport.request(:post, "#{svc_root}/ConversationWithParticipants",
                           form: build_form(CONV_WITH_PARTICIPANTS_FIELDS, kwargs))
      )
    end

    # --- ServiceParticipantConversation (list only) ---
    def list_participant_conversations(identity: nil, address: nil, page_size: nil)
      params = {}
      params['Identity'] = identity unless identity.nil?
      params['Address']  = address  unless address.nil?
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceParticipantConversationList.new(
        @transport.request(:get, "#{svc_root}/ParticipantConversations", params: params)
      )
    end

    # --- ServiceUserConversation (list only, under Users/{Sid}/Conversations) ---
    def list_user_conversations(user_sid, page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceUserConversationList.new(
        @transport.request(:get, "#{svc_root}/Users/#{user_sid}/Conversations", params: params)
      )
    end

    # --- ServiceRole (5 CRUD) ---
    def list_roles(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceRoleList.new(
        @transport.request(:get, "#{svc_root}/Roles", params: params)
      )
    end

    def create_role(friendly_name:, type:, permission:)
      form = { 'FriendlyName' => friendly_name, 'Type' => type, 'Permission' => Array(permission) }
      ConversationsV1ServiceRole.from_hash(
        @transport.request(:post, "#{svc_root}/Roles", form: form)
      )
    end

    def fetch_role(role_sid)
      ConversationsV1ServiceRole.from_hash(
        @transport.request(:get, "#{svc_root}/Roles/#{role_sid}")
      )
    end

    def update_role(role_sid, permission:)
      form = { 'Permission' => Array(permission) }
      ConversationsV1ServiceRole.from_hash(
        @transport.request(:post, "#{svc_root}/Roles/#{role_sid}", form: form)
      )
    end

    def delete_role(role_sid)
      @transport.request(:delete, "#{svc_root}/Roles/#{role_sid}")
      nil
    end

    # --- ServiceUser (5 CRUD) ---
    def list_users(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      ConversationsV1ServiceUserList.new(
        @transport.request(:get, "#{svc_root}/Users", params: params)
      )
    end

    def create_user(identity:, friendly_name: nil, attributes: nil, role_sid: nil)
      kwargs = { identity: identity, friendly_name: friendly_name,
                 attributes: attributes, role_sid: role_sid }
      ConversationsV1ServiceUser.from_hash(
        @transport.request(:post, "#{svc_root}/Users", form: build_form(USER_FIELDS, kwargs))
      )
    end

    def fetch_user(user_sid)
      ConversationsV1ServiceUser.from_hash(
        @transport.request(:get, "#{svc_root}/Users/#{user_sid}")
      )
    end

    def update_user(user_sid, **kwargs)
      ConversationsV1ServiceUser.from_hash(
        @transport.request(:post, "#{svc_root}/Users/#{user_sid}",
                           form: build_form(USER_UPDATE_FIELDS, kwargs))
      )
    end

    def delete_user(user_sid)
      @transport.request(:delete, "#{svc_root}/Users/#{user_sid}")
      nil
    end

    # --- ServiceBinding (list/fetch/delete only) ---
    def list_bindings(binding_type: nil, identity: nil, page_size: nil)
      params = {}
      params['BindingType'] = binding_type unless binding_type.nil?
      params['Identity']    = identity     unless identity.nil?
      params['PageSize']    = page_size    unless page_size.nil?
      ConversationsV1ServiceBindingList.new(
        @transport.request(:get, "#{svc_root}/Bindings", params: params)
      )
    end

    def fetch_binding(sid)
      ConversationsV1ServiceBinding.from_hash(
        @transport.request(:get, "#{svc_root}/Bindings/#{sid}")
      )
    end

    def delete_binding(sid)
      @transport.request(:delete, "#{svc_root}/Bindings/#{sid}")
      nil
    end

    # --- ServiceConfiguration (fetch+update singleton) ---
    def fetch_configuration
      ConversationsV1ServiceConfiguration.from_hash(
        @transport.request(:get, "#{svc_root}/Configuration")
      )
    end

    def update_configuration(**kwargs)
      ConversationsV1ServiceConfiguration.from_hash(
        @transport.request(:post, "#{svc_root}/Configuration",
                           form: build_form(CONFIG_UPDATE_FIELDS, kwargs))
      )
    end

    # --- ServiceNotification (fetch+update singleton) ---
    def fetch_notifications
      ConversationsV1ServiceNotification.from_hash(
        @transport.request(:get, "#{svc_root}/Configuration/Notifications")
      )
    end

    def update_notifications(**kwargs)
      ConversationsV1ServiceNotification.from_hash(
        @transport.request(:post, "#{svc_root}/Configuration/Notifications",
                           form: build_form(NOTIFICATION_UPDATE_FIELDS, kwargs))
      )
    end

    # --- ServiceWebhookConfiguration (fetch+update singleton) ---
    def fetch_webhook_configuration
      ConversationsV1ServiceWebhookConfiguration.from_hash(
        @transport.request(:get, "#{svc_root}/Configuration/Webhooks")
      )
    end

    def update_webhook_configuration(**kwargs)
      ConversationsV1ServiceWebhookConfiguration.from_hash(
        @transport.request(:post, "#{svc_root}/Configuration/Webhooks",
                           form: build_form(WEBHOOK_CONFIG_UPDATE_FIELDS, kwargs))
      )
    end

    private

    def svc_root
      "/v1/Services/#{@chat_service_sid}"
    end

    def conv_root
      "#{svc_root}/Conversations"
    end

    def build_form(map, kwargs)
      out = {}
      map.each do |wire, k|
        value = kwargs[k]
        next if value.nil?

        out[wire] = value
      end
      out
    end
  end
end
