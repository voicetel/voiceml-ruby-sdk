# frozen_string_literal: true

require_relative 'base'
require_relative '../models/messages'

module VoiceML
  # Operations on `/Messages` — VoiceTel's Twilio-compatible SMS surface,
  # backed by the SDK 2.2 gateway. Outbound-only today (no MMS, no inbound
  # webhook delivery).
  #
  # All methods accept idiomatic snake_case keyword arguments — they're
  # translated to the PascalCase wire names internally.
  class MessagesResource < BaseResource
    CREATE_FIELDS = {
      'To'                   => :to,
      'Body'                 => :body,
      'From'                 => :from,
      'MessagingServiceSid'  => :messaging_service_sid,
      'StatusCallback'       => :status_callback
    }.freeze

    LIST_FIELDS = {
      'To'         => :to,
      'From'       => :from,
      'DateSent'   => :date_sent,
      'DateSent<'  => :date_sent_lt,
      'DateSent>'  => :date_sent_gt,
      'Page'       => :page,
      'PageSize'   => :page_size,
      'PageToken'  => :page_token
    }.freeze

    UPDATE_FIELDS = {
      'Body'   => :body,
      'Status' => :status
    }.freeze

    # Dispatch an outbound SMS. `to:` and `body:` are required; `from:` falls
    # back to the tenant's configured default sender when omitted.
    #
    # @return [VoiceML::Message]
    def create(**kwargs)
      data = @transport.request(:post, path('Messages'), form: form_params(CREATE_FIELDS, kwargs))
      Message.from_hash(data)
    end

    # Retrieve a previously-sent Message by sid.
    #
    # @return [VoiceML::Message]
    def fetch(sid)
      Message.from_hash(@transport.request(:get, path('Messages', sid)))
    end

    # Return a single page of Messages, narrowed by the Twilio-documented filter
    # set (To, From, DateSent eq/gt/lt) plus pagination.
    #
    # @return [VoiceML::MessageList]
    def list(**kwargs)
      MessageList.from_hash(
        @transport.request(:get, path('Messages'), params: form_params(LIST_FIELDS, kwargs))
      )
    end

    # Walk every page of /Messages and yield each Message. Returns an Enumerator
    # when called without a block.
    #
    # @yield [VoiceML::Message]
    # @return [Enumerator<VoiceML::Message>] when no block given
    def each(**kwargs, &block)
      return enum_for(:each, **kwargs) unless block

      page_num = kwargs.delete(:page) || 0
      loop do
        chunk = list(**kwargs, page: page_num)
        chunk.messages.each(&block)
        break if chunk.next_page_uri.nil? || chunk.next_page_uri.empty? || chunk.messages.empty?

        page_num += 1
      end
    end

    # Mutate an existing Message — redact `body:` to empty string, or attempt
    # `status: "canceled"`. Cancellation returns 21610 today because the gateway
    # is fire-and-forget.
    #
    # @return [VoiceML::Message]
    def update(sid, **kwargs)
      data = @transport.request(:post, path('Messages', sid),
                                form: form_params(UPDATE_FIELDS, kwargs))
      Message.from_hash(data)
    end

    # Remove a Message resource from the account's store.
    #
    # @return [nil]
    def delete(sid)
      @transport.request(:delete, path('Messages', sid))
      nil
    end
  end
end
