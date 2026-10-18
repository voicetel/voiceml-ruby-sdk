# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Twilio-compatible Account resource. The voiceml SDK is single-account
  # (the credential's account is implicit on every call), so this model
  # exists primarily to decode `GET/POST /Accounts/{Sid}.json` responses
  # in the Twilio-compatible wire format — useful for migration tooling
  # that echoes the account record back to the caller.
  class Account
    ATTRIBUTES = %w[
      sid friendly_name status type owner_account_sid
      date_created date_updated subresource_uris uri
    ].freeze

    attr_reader(*ATTRIBUTES.map(&:to_sym))

    def initialize(attrs = {})
      @raw_attributes = attrs
      ATTRIBUTES.each do |field|
        value = attrs.key?(field) ? attrs[field] : attrs[field.to_sym]
        instance_variable_set("@#{field}", value)
      end
    end

    def self.from_hash(hash)
      return nil if hash.nil?

      new(hash)
    end
  end

  # `GET /Accounts/{Sid}/Balance.json` — running balance for the account in
  # the account's settlement currency. No `sid` field on the wire (the
  # balance is account-scoped, not its own resource).
  class Balance
    include RawAttributes
    ATTRIBUTES = %w[account_sid balance currency].freeze

    attr_reader(*ATTRIBUTES.map(&:to_sym))

    def initialize(attrs = {})
      @raw_attributes = attrs
      ATTRIBUTES.each do |field|
        value = attrs.key?(field) ? attrs[field] : attrs[field.to_sym]
        instance_variable_set("@#{field}", value)
      end
    end

    def self.from_hash(hash)
      return nil if hash.nil?

      new(hash)
    end
  end

  # `POST /Accounts/{Sid}/RotateKey` response — the account configuration
  # view plus the freshly generated `api_key`. No read endpoint returns the
  # key, so store it right away; requests signed with the previous key fail
  # with 401 from that point on. The key is secret material and never
  # appears in `inspect` / `to_s` output.
  class AccountWithKey
    include RawAttributes
    ATTRIBUTES = %w[
      sid api_key sip_username name phone_regions allow_cidr disabled
      stt_fs_vendor stt_http_url stt_http_token_set tts_http_url
      tts_http_token_set tts_engine_name tts_default_voice tts_default_language
      stripe_secret_key_set pay_enabled sms_provider sms_allowed_providers
      stt_allowed_providers stt_provider voice_url voice_method
      voice_fallback_url voice_fallback_method aws_bucket aws_region
      aws_prefix aws_access_key_id aws_secret_access_key_set aws_kms_key_id
      created_at updated_at
    ].freeze

    attr_reader(*ATTRIBUTES.map(&:to_sym))

    def initialize(attrs = {})
      @raw_attributes = attrs
      ATTRIBUTES.each do |field|
        value = attrs.key?(field) ? attrs[field] : attrs[field.to_sym]
        instance_variable_set("@#{field}", value)
      end
    end

    def self.from_hash(hash)
      return nil if hash.nil?

      new(hash)
    end

    # A redacted dump: never includes the api_key.
    def inspect
      "#<#{self.class.name} sid=#{@sid}>"
    end
    alias to_s inspect
  end
end
