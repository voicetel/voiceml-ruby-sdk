# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # A Twilio-shape Conference resource.
  class Conference
    ATTRIBUTES = %w[
      sid account_sid friendly_name status region api_version uri
      date_created date_updated reason_conference_ended
      call_sid_ending_conference subresource_uris member_count
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

  # Paginated `GET /Conferences` response.
  class ConferenceList
    include Pageable

    attr_reader :conferences

    def initialize(hash = {})
      assign_page_fields(hash)
      @conferences = (hash['conferences'] || []).map { |c| Conference.from_hash(c) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end

  # A participant in a live conference.
  class Participant
    ATTRIBUTES = %w[
      call_sid conference_sid account_sid muted hold coaching call_sid_to_coach queue_time
      start_conference_on_enter end_conference_on_exit status label
      api_version uri date_created date_updated
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

  # Paginated `GET /Conferences/{Sid}/Participants` response.
  class ParticipantList
    include Pageable

    attr_reader :participants

    def initialize(hash = {})
      assign_page_fields(hash)
      @participants = (hash['participants'] || []).map { |p| Participant.from_hash(p) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end
