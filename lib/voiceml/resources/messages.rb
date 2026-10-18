# frozen_string_literal: true

require_relative 'base'
require_relative '../models/messages'
require_relative '../models/media'

module VoiceML
  # Operations on `/Messages` — VoiceTel's Twilio-compatible SMS/MMS surface,
  # backed by the SDK 2.2 gateway.
  #
  # All methods accept idiomatic snake_case keyword arguments — they're
  # translated to the PascalCase wire names internally. Unknown kwargs raise
  # `ArgumentError`.
  class MessagesResource < BaseResource
    CREATE_FIELDS = {
      'To'                   => :to,
      'Body'                 => :body,
      'MediaUrl'             => :media_url,
      'From'                 => :from,
      'MessagingServiceSid'  => :messaging_service_sid,
      'ValidityPeriod'       => :validity_period,
      'StatusCallback'       => :status_callback,
      'StatusCallbackMethod' => :status_callback_method
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

    FEEDBACK_FIELDS = {
      'Outcome' => :outcome
    }.freeze

    LIST_MEDIA_FIELDS = {
      'DateCreated'  => :date_created,
      'DateCreated<' => :date_created_lt,
      'DateCreated>' => :date_created_gt,
      'Page'         => :page,
      'PageSize'     => :page_size,
      'PageToken'    => :page_token
    }.freeze

    # Dispatch an outbound SMS or MMS. `to:` is required, plus at least one of
    # `body:` (SMS text) or `media_url:` (MMS media; pass a string or an array —
    # repeated keys are sent on the wire). `from:` falls back to the tenant's
    # configured default sender when omitted.
    #
    # @return [VoiceML::Message]
    def create(**kwargs)
      form = form_params(CREATE_FIELDS, kwargs)
      raise ArgumentError, 'to: is required' if form['To'].nil?
      raise ArgumentError, 'either body: or media_url: is required' if form['Body'].nil? && form['MediaUrl'].nil?

      data = @transport.request(:post, path('Messages'), form: form)
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

    # Walk every page of /Messages and yield each Message, following the
    # envelope's `next_page_uri` verbatim (the server requires its `PageToken`
    # on page 2+). Returns an Enumerator when called without a block.
    #
    # @yield [VoiceML::Message]
    # @return [Enumerator<VoiceML::Message>] when no block given
    def each(**kwargs, &block)
      return enum_for(:each, **kwargs) unless block

      page = list(**kwargs)
      loop do
        page.messages.each(&block)
        nxt = next_page(page)
        break if nxt.nil?

        page = nxt
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

    # Submit delivery feedback for a Message
    # (`POST /Messages/{Sid}/Feedback.json`). `outcome:` is `"confirmed"` or
    # `"unconfirmed"`; any other value echoes back as `unconfirmed` and the
    # feedback is not persisted.
    #
    # @return [VoiceML::MessageFeedback]
    def create_feedback(sid, outcome:)
      MessageFeedback.from_hash(
        @transport.request(:post, path('Messages', sid, 'Feedback'),
                           form: form_params(FEEDBACK_FIELDS, { outcome: outcome }))
      )
    end

    # Remove a Message resource from the account's store.
    #
    # @return [nil]
    def delete(sid)
      @transport.request(:delete, path('Messages', sid))
      nil
    end

    # --- Media (`/Messages/{MessageSid}/Media`) ---

    # List the media items of a message.
    #
    # @return [VoiceML::MediaList]
    def list_media(message_sid, **kwargs)
      MediaList.from_hash(
        @transport.request(:get, path('Messages', message_sid, 'Media'),
                           params: form_params(LIST_MEDIA_FIELDS, kwargs))
      )
    end

    # Fetch one media item's metadata.
    #
    # @return [VoiceML::Media]
    def get_media(message_sid, sid)
      Media.from_hash(@transport.request(:get, path('Messages', message_sid, 'Media', sid)))
    end

    # Delete a media item.
    #
    # @return [nil]
    def delete_media(message_sid, sid)
      @transport.request(:delete, path('Messages', message_sid, 'Media', sid))
      nil
    end
  end
end
