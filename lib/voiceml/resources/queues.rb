# frozen_string_literal: true

require_relative 'base'
require_relative '../models/queues'

module VoiceML
  # Operations on `/Queues` and their members.
  class QueuesResource < BaseResource
    QUEUE_FIELDS = {
      'FriendlyName' => :friendly_name,
      'MaxSize'      => :max_size
    }.freeze

    DEQUEUE_FIELDS = {
      'Url'    => :url,
      'Method' => :method
    }.freeze

    LIST_PAGE_FIELDS = {
      'Page'      => :page,
      'PageSize'  => :page_size,
      'PageToken' => :page_token
    }.freeze

    LIST_MEMBERS_FIELDS = {
      'Page'      => :page,
      'PageSize'  => :page_size,
      'PageToken' => :page_token
    }.freeze

    # @return [VoiceML::Queue]
    def create(**kwargs)
      Queue.from_hash(
        @transport.request(:post, path('Queues'), form: form_params(QUEUE_FIELDS, kwargs))
      )
    end

    # @return [VoiceML::QueueList]
    def list(**kwargs)
      QueueList.from_hash(
        @transport.request(:get, path('Queues'), params: form_params(LIST_PAGE_FIELDS, kwargs))
      )
    end

    # @yield [VoiceML::Queue]
    # @return [Enumerator<VoiceML::Queue>] when no block given
    def each(**kwargs, &block)
      return enum_for(:each, **kwargs) unless block

      page_num = kwargs.delete(:page) || 0
      loop do
        chunk = list(**kwargs, page: page_num)
        chunk.queues.each(&block)
        break if chunk.next_page_uri.nil? || chunk.next_page_uri.empty? || chunk.queues.empty?
        page_num += 1
      end
    end

    # @return [VoiceML::Queue]
    def get(queue_sid)
      Queue.from_hash(@transport.request(:get, path('Queues', queue_sid)))
    end

    # @return [VoiceML::Queue]
    def update(queue_sid, **kwargs)
      Queue.from_hash(
        @transport.request(:post, path('Queues', queue_sid),
                           form: form_params(QUEUE_FIELDS, kwargs))
      )
    end

    # @return [nil]
    def delete(queue_sid)
      @transport.request(:delete, path('Queues', queue_sid))
      nil
    end

    # --- Members ---

    # @return [VoiceML::QueueMemberList]
    def list_members(queue_sid, **kwargs)
      QueueMemberList.from_hash(
        @transport.request(:get, path('Queues', queue_sid, 'Members'),
                           params: form_params(LIST_MEMBERS_FIELDS, kwargs))
      )
    end

    # @return [VoiceML::QueueMember]
    def peek_front(queue_sid)
      QueueMember.from_hash(
        @transport.request(:get, path('Queues', queue_sid, 'Members', 'Front'))
      )
    end

    # Dequeue the front-of-queue member to a TwiML URL.
    # @return [VoiceML::QueueMember]
    def dequeue_front(queue_sid, **kwargs)
      QueueMember.from_hash(
        @transport.request(:post, path('Queues', queue_sid, 'Members', 'Front'),
                           form: form_params(DEQUEUE_FIELDS, kwargs))
      )
    end

    # @return [VoiceML::QueueMember]
    def get_member(queue_sid, call_sid)
      QueueMember.from_hash(
        @transport.request(:get, path('Queues', queue_sid, 'Members', call_sid))
      )
    end

    # Dequeue a specific member by CallSid.
    # @return [VoiceML::QueueMember]
    def dequeue_member(queue_sid, call_sid, **kwargs)
      QueueMember.from_hash(
        @transport.request(:post, path('Queues', queue_sid, 'Members', call_sid),
                           form: form_params(DEQUEUE_FIELDS, kwargs))
      )
    end
  end
end
