# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Monitor v1 (`/v1/Alerts`) — failure events rendered in the Monitor Alert
  # shape: call-scoped errors and messaging delivery failures alike.
  #
  # List rows omit the request/response detail; `fetch` includes it when the
  # underlying event stored any (`request_headers`, `request_variables`,
  # `response_body`, `response_headers`).
  class MonitorAlert
    include RawAttributes
    ATTRIBUTES = %w[
      sid account_sid alert_text api_version error_code log_level more_info
      request_method request_url request_headers request_variables
      response_body response_headers resource_sid service_sid
      date_created date_generated date_updated url
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

  # Paginated `GET /v1/Alerts` response: `alerts` plus the standard `/v1`
  # `meta` envelope. The server serves a single page
  # (`meta.next_page_url` is always `null`); `PageSize` does limit this
  # collection (default 50, capped at 1000).
  class MonitorAlertList
    include RawAttributes
    include V1Pageable

    attr_reader :alerts

    def initialize(hash = {})
      @raw_attributes = hash
      assign_meta_fields(hash)
      @alerts = (hash['alerts'] || []).map { |h| MonitorAlert.from_hash(h) }
    end
  end
end
