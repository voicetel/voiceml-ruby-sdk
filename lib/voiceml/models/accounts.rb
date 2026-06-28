# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Twilio-compatible Account resource. The voiceml SDK is single-account
  # (the credential's account is implicit on every call), so this model
  # exists primarily to decode `GET/POST /Accounts/{Sid}.json` responses
  # round-trip with the Twilio shape — useful for migration tooling that
  # echoes the account record back to the caller.
  class Account
    ATTRIBUTES = %w[
      sid friendly_name status type auth_token owner_account_sid
      date_created date_updated subresource_uris uri
    ].freeze

    attr_reader(*ATTRIBUTES.map(&:to_sym))

    def initialize(attrs = {})
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
    ATTRIBUTES = %w[account_sid balance currency].freeze

    attr_reader(*ATTRIBUTES.map(&:to_sym))

    def initialize(attrs = {})
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
end
