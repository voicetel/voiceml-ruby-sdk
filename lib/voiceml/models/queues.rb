# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # A Twilio-shape Queue resource.
  class Queue
    ATTRIBUTES = %w[
      sid account_sid friendly_name current_size max_size
      average_wait_time date_created date_updated uri
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

  # Paginated `GET /Queues` response.
  class QueueList
    include Pageable

    attr_reader :queues

    def initialize(hash = {})
      assign_page_fields(hash)
      @queues = (hash['queues'] || []).map { |q| Queue.from_hash(q) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end

  # A member (call) waiting in a queue.
  class QueueMember
    ATTRIBUTES = %w[
      call_sid queue_sid account_sid date_enqueued wait_time position uri
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

  # Paginated `GET /Queues/{Sid}/Members` response.
  class QueueMemberList
    include Pageable

    attr_reader :queue_members

    def initialize(hash = {})
      assign_page_fields(hash)
      @queue_members = (hash['queue_members'] || []).map { |m| QueueMember.from_hash(m) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end
