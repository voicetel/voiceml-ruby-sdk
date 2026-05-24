# frozen_string_literal: true

module VoiceML
  # Twilio-compatible pagination envelope fields. Mix into list-response classes to expose
  # `page`, `page_size`, `total`, `next_page_uri`, `previous_page_uri`, `first_page_uri`,
  # `uri`, `num_pages`, `start`, `end`. The list items themselves are declared on each
  # concrete subclass (`calls`, `conferences`, etc).
  module Pageable
    PAGE_FIELDS = %w[
      page page_size num_pages total start end
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
