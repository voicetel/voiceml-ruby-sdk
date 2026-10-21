# frozen_string_literal: true

require_relative 'base'
require_relative '../models/outgoing_caller_ids'

module VoiceML
  # Operations on `/OutgoingCallerIds` — verified caller-id numbers.
  class OutgoingCallerIdsResource < BaseResource
    LIST_FIELDS = {
      'PhoneNumber'  => :phone_number,
      'FriendlyName' => :friendly_name,
      'Page'         => :page,
      'PageSize'     => :page_size,
      'PageToken'    => :page_token
    }.freeze

    CREATE_FIELDS = {
      'PhoneNumber'          => :phone_number,
      'FriendlyName'         => :friendly_name,
      'CallDelay'            => :call_delay,
      'Extension'            => :extension,
      'StatusCallback'       => :status_callback,
      'StatusCallbackMethod' => :status_callback_method
    }.freeze

    UPDATE_FIELDS = {
      'FriendlyName' => :friendly_name
    }.freeze

    # List verified outgoing caller ids.
    #
    # @return [VoiceML::OutgoingCallerIdList]
    def list(**kwargs)
      OutgoingCallerIdList.from_hash(
        @transport.request(:get, path('OutgoingCallerIds'),
                           params: form_params(LIST_FIELDS, kwargs))
      )
    end

    # Start verification of a new outgoing caller id. The server places a
    # validation call; the returned `VoiceML::ValidationRequest` carries the
    # `validation_code` the user must enter on that call.
    #
    # @param phone_number [String] required. E.164.
    # @param friendly_name [String, nil] display label.
    # @param call_delay [Integer, nil] seconds to wait before placing the
    #   verification call (0-60).
    # @param extension [String, nil] DTMF extension dialed after the
    #   verification call connects.
    # @param status_callback [String, nil] fires at the end of the verification
    #   call with the verification outcome.
    # @param status_callback_method [String, nil] HTTP method for
    #   `status_callback` (`GET`/`POST`).
    # @return [VoiceML::ValidationRequest]
    def create(phone_number:, friendly_name: nil, call_delay: nil, extension: nil,
               status_callback: nil, status_callback_method: nil)
      ValidationRequest.from_hash(
        @transport.request(:post, path('OutgoingCallerIds'),
                           form: form_params(CREATE_FIELDS,
                                             { phone_number: phone_number,
                                               friendly_name: friendly_name,
                                               call_delay: call_delay,
                                               extension: extension,
                                               status_callback: status_callback,
                                               status_callback_method: status_callback_method }))
      )
    end

    # Fetch a verified caller id by its `PN`-prefixed sid.
    #
    # @return [VoiceML::OutgoingCallerId]
    def fetch(sid)
      OutgoingCallerId.from_hash(@transport.request(:get, path('OutgoingCallerIds', sid)))
    end

    # Update a caller id's friendly name.
    #
    # @return [VoiceML::OutgoingCallerId]
    def update(sid, friendly_name: nil)
      OutgoingCallerId.from_hash(
        @transport.request(:post, path('OutgoingCallerIds', sid),
                           form: form_params(UPDATE_FIELDS, { friendly_name: friendly_name }))
      )
    end

    # Remove a caller id.
    #
    # @return [nil]
    def delete(sid)
      @transport.request(:delete, path('OutgoingCallerIds', sid))
      nil
    end
  end
end
