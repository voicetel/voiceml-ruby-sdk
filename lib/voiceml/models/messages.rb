# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # A Twilio-compatible Message resource.
  #
  # VoiceML's outbound SMS today is fire-and-forget through the SDK 2.2 gateway —
  # `status` pins to `"sent"` on successful dispatch and `"failed"` otherwise.
  # There is no in-flight `queued`/`sending`/`delivered` lifecycle.
  #
  # Two wire shapes deserve a note:
  #
  # - `num_segments` and `num_media` are **strings** on the wire (Twilio-compatible),
  #   not integers. `num_media` is always `"0"` because the gateway has no MMS today.
  # - `error_code` is a nullable integer; `error_message`, `price`, `price_unit`,
  #   `date_sent`, and `messaging_service_sid` are nullable strings.
  class Message
    include RawAttributes
    ATTRIBUTES = %w[
      sid account_sid api_version to from body status num_segments num_media
      direction price price_unit error_code error_message messaging_service_sid
      date_created date_updated date_sent uri subresource_uris
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

  # Paginated `GET /Messages` response.
  class MessageList
    include RawAttributes
    include Pageable

    attr_reader :messages

    def initialize(hash = {})
      @raw_attributes = hash
      assign_page_fields(hash)
      @messages = (hash['messages'] || []).map { |m| Message.from_hash(m) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end

  # Delivery-quality feedback echoed back on a Message
  # (`POST /Messages/{Sid}/Feedback.json`). VoiceML records the outcome on
  # the response only; there is no separate downstream analytics surface.
  # Any submitted `Outcome` other than `confirmed` echoes as `unconfirmed`.
  class MessageFeedback
    include RawAttributes
    ATTRIBUTES = %w[account_sid message_sid outcome date_created date_updated uri].freeze

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
end
