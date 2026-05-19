# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # `GET /Calls/{Sid}/Notifications` — always an empty list (Twilio-compat stub).
  class NotificationsList
    attr_reader :notifications, :page, :page_size, :total, :uri

    def initialize(hash = {})
      @notifications = hash['notifications'] || []
      @page          = hash['page']     || 0
      @page_size     = hash['page_size'] || 0
      @total         = hash['total']    || 0
      @uri           = hash['uri']
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end

  # `GET /Calls/{Sid}/Events` — always an empty list (Twilio-compat stub).
  # The canonical event source is the customer's StatusCallback URL.
  class EventsList
    attr_reader :events, :page, :page_size, :total, :uri

    def initialize(hash = {})
      @events    = hash['events']    || []
      @page      = hash['page']      || 0
      @page_size = hash['page_size'] || 0
      @total     = hash['total']     || 0
      @uri       = hash['uri']
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end

  # `GET /health` response. Hard-check failures flip `ok` to false (server returns 503);
  # soft-check warnings surface in `warnings` only.
  class HealthStatus
    attr_reader :ok, :warnings, :failures

    def initialize(hash = {})
      @ok        = hash['ok']
      @warnings  = (hash['warnings'] || []).map { |w| HealthFailure.from_hash(w) }
      @failures  = (hash['failures'] || []).map { |f| HealthFailure.from_hash(f) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end
