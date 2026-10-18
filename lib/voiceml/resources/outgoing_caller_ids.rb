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
      'PhoneNumber'  => :phone_number,
      'FriendlyName' => :friendly_name
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
    # @return [VoiceML::ValidationRequest]
    def create(phone_number:, friendly_name: nil)
      ValidationRequest.from_hash(
        @transport.request(:post, path('OutgoingCallerIds'),
                           form: form_params(CREATE_FIELDS,
                                             { phone_number: phone_number,
                                               friendly_name: friendly_name }))
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
