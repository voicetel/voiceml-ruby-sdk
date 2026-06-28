# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Twilio-compatible MMS Media item. VoiceML's outbound SMS gateway is
  # text-only today (no MMS), so this model exists primarily for response-
  # shape conformance and to round-trip migrated tooling. `parent_sid` ties
  # the media back to its parent Message (SM... sid).
  class Media
    ATTRIBUTES = %w[
      sid account_sid parent_sid content_type
      date_created date_updated uri
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

  # Paginated `GET /Messages/{Sid}/Media` response. Twilio's envelope key is
  # `media_list` (not `media`) — the SDK preserves that on the wire.
  class MediaList
    include Pageable

    attr_reader :media_list

    def initialize(hash = {})
      assign_page_fields(hash)
      @media_list = (hash['media_list'] || []).map { |m| Media.from_hash(m) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end
