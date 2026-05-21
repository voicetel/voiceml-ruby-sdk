# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # A Twilio-shape Recording resource.
  class Recording
    ATTRIBUTES = %w[
      sid account_sid call_sid conference_sid status source channels
      duration api_version uri date_created date_updated start_time
      price price_unit encryption_details subresource_uris media_url error_code
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

  # `GET /Recordings` (account-scoped) and `GET /Calls/{Sid}/Recordings` (per-call) response.
  # The per-call form populates only `recordings`; pagination fields remain `nil`.
  class RecordingList
    include Pageable

    attr_reader :recordings

    def initialize(hash = {})
      assign_page_fields(hash)
      @recordings = (hash['recordings'] || []).map { |r| Recording.from_hash(r) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end

  # Result of fetching `GET /Recordings/{Sid}.wav`. Wraps the WAV bytes with the response's
  # content-type and whether we followed a 302 -> S3 redirect to retrieve them.
  class RecordingAudio
    attr_reader :sid, :content, :content_type, :via_redirect

    def initialize(sid:, content:, content_type:, via_redirect:)
      @sid          = sid
      @content      = content
      @content_type = content_type
      @via_redirect = via_redirect
    end
  end
end
