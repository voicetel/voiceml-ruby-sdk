# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # One day's archive entry from `GET /Exports`.
  class Export
    include RawAttributes
    ATTRIBUTES = %w[date size uri].freeze

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

  # `GET /Exports` response — the account's available archives, newest first.
  class ExportList
    include RawAttributes

    attr_reader :account_sid, :uri, :exports

    def initialize(hash = {})
      @raw_attributes = hash
      @account_sid = hash['account_sid']
      @uri         = hash['uri']
      @exports     = (hash['exports'] || []).map { |e| Export.from_hash(e) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end

  # Result of `GET /Exports/{Date}` — the archive bytes, following the same
  # 302 -> presigned-object redirect recording audio uses.
  class ExportDownload
    attr_reader :date, :content, :content_type, :via_redirect

    def initialize(date:, content:, content_type:, via_redirect:)
      @date         = date
      @content      = content
      @content_type = content_type
      @via_redirect = via_redirect
    end
  end
end
