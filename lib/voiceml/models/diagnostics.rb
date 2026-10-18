# frozen_string_literal: true

require_relative 'common'
require_relative 'notifications'

module VoiceML
  # `GET /Calls/{Sid}/Notifications` — always an empty list (Twilio-compat stub).
  class NotificationsList
    include RawAttributes
    include Pageable
    attr_reader :notifications

    def initialize(hash = {})
      @raw_attributes = hash
      assign_page_fields(hash)
      @notifications = (hash['notifications'] || []).map { |n| Notification.from_hash(n) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end

  # `GET /Calls/{Sid}/Events` — always an empty list (Twilio-compat stub).
  # The canonical event source is the customer's StatusCallback URL.
  class EventsList
    include RawAttributes
    include Pageable
    attr_reader :events

    def initialize(hash = {})
      @raw_attributes = hash
      assign_page_fields(hash)
      @events = (hash['events'] || []).map { |event| CallEvent.from_hash(event) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end

  # Request/response pair from a call's event log.
  class CallEvent
    include RawAttributes
    ATTRIBUTES = %w[request response].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))

    def initialize(attrs = {})
      @raw_attributes = attrs
      ATTRIBUTES.each do |field|
        instance_variable_set("@#{field}", attrs.key?(field) ? attrs[field] : attrs[field.to_sym])
      end
    end

    def self.from_hash(hash)
      hash.nil? ? nil : new(hash)
    end
  end

  # `GET /health` response. Hard-check failures flip `ok` to false (server returns 503);
  # soft-check warnings surface in `warnings` only.
  class HealthStatus
    include RawAttributes
    attr_reader :ok, :warnings, :failures

    def initialize(hash = {})
      @raw_attributes = hash
      @ok        = hash['ok']
      @warnings  = (hash['warnings'] || []).map { |w| HealthFailure.from_hash(w) }
      @failures  = (hash['failures'] || []).map { |f| HealthFailure.from_hash(f) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end
