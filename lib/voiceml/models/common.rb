# frozen_string_literal: true

module VoiceML
  # Twilio-compatible pagination envelope fields. Mix into list-response classes to expose
  # `page`, `page_size`, `start`, `end`, `first_page_uri`, `next_page_uri`, `previous_page_uri`,
  # `uri`. The list items themselves are declared on each concrete subclass (`calls`,
  # `conferences`, etc).
  module Pageable
    PAGE_FIELDS = %w[
      page page_size start end
      first_page_uri next_page_uri previous_page_uri uri
    ].freeze

    PAGE_FIELDS.each do |field|
      attr_reader field.to_sym
    end

    def assign_page_fields(hash)
      PAGE_FIELDS.each do |field|
        instance_variable_set("@#{field}", hash[field])
      end
    end
  end

  # Shared `meta` envelope for `/v1/*` list responses.
  module V1Pageable
    META_FIELDS = %w[first_page_url next_page_url previous_page_url url page page_size key].freeze

    META_FIELDS.each { |f| attr_reader f.to_sym }

    def assign_meta_fields(hash)
      meta = hash['meta'] || {}
      META_FIELDS.each { |f| instance_variable_set("@#{f}", meta[f]) }
    end
  end

  # Mixed into every response model: keeps the raw wire hash readable via
  # `#to_h` / `#[]` so fields the SDK does not model yet (or newly added
  # server-side) stay accessible without an SDK release. Unknown fields are
  # ignored by the typed readers.
  module RawAttributes
    # The raw response hash this model was decoded from.
    def to_h
      @raw_attributes ||= {}
    end

    # Read one field from the raw response hash, by either its wire (string)
    # or symbol name. Returns `nil` for absent fields; `false` round-trips.
    def [](key)
      raw = to_h
      string_key = key.to_s
      raw.key?(string_key) ? raw[string_key] : raw[key.to_sym]
    end
  end

  # Twilio-compatible error body. Surface only — the transport raises a VoiceML::ApiError
  # subclass with this payload attached as `error.body`.
  class ErrorBody
    attr_reader :code, :message, :more_info, :status

    def initialize(code: nil, message: nil, more_info: nil, status: nil)
      @code      = code
      @message   = message
      @more_info = more_info
      @status    = status
    end

    def self.from_hash(hash)
      return nil if hash.nil?

      new(
        code:      hash['code'],
        message:   hash['message'],
        more_info: hash['more_info'],
        status:    hash['status']
      )
    end
  end

  # One tripped check from the `/health` deep probe.
  class HealthFailure
    attr_reader :check, :detail

    def initialize(check:, detail:)
      @check  = check
      @detail = detail
    end

    def self.from_hash(hash)
      return nil if hash.nil?

      new(check: hash['check'], detail: hash['detail'])
    end
  end
end
