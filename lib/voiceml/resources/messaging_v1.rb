# frozen_string_literal: true

require_relative 'base'
require_relative '../models/messaging_v1'

module VoiceML
  # `client.messaging_v1` — Twilio Messaging v1 (messaging.twilio.com/v1).
  # The whole group is routed at the messaging host (`messaging.voicetel.com`) by the
  # client, which is what disambiguates a Messaging Service (`MG...`) from a
  # Conversation Service (`IS...`) — they share the `/v1/Services` path shape.
  class MessagingV1Resource
    attr_reader :services

    def initialize(transport)
      @services = MessagingV1ServicesResource.new(transport)
    end
  end

  # Operations on `/v1/Services` at the messaging host.
  #
  # `create` / `list` / `fetch` / `delete` reuse the shared path; `update`
  # (`POST /v1/Services/{sid}`) is unique to Messaging Service.
  class MessagingV1ServicesResource
    include V1Pages
    include FieldMapping

    SERVICE_FIELDS = {
      'FriendlyName' => :friendly_name,
      'InboundRequestUrl' => :inbound_request_url,
      'InboundMethod' => :inbound_method,
      'FallbackUrl' => :fallback_url,
      'FallbackMethod' => :fallback_method,
      'StatusCallback' => :status_callback,
      'StickySender' => :sticky_sender,
      'MmsConverter' => :mms_converter,
      'SmartEncoding' => :smart_encoding,
      'ScanMessageContent' => :scan_message_content,
      'FallbackToLongCode' => :fallback_to_long_code,
      'AreaCodeGeomatch' => :area_code_geomatch,
      'SynchronousValidation' => :synchronous_validation,
      'ValidityPeriod' => :validity_period,
      'Usecase' => :usecase,
      'UseInboundWebhookOnNumber' => :use_inbound_webhook_on_number
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    def create(friendly_name:, **kwargs)
      kwargs[:friendly_name] = friendly_name
      MessagingService.from_hash(
        @transport.request(:post, '/v1/Services', form: form_params(SERVICE_FIELDS, kwargs))
      )
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      MessagingServiceList.new(@transport.request(:get, '/v1/Services', params: params))
    end

    def fetch(sid)
      MessagingService.from_hash(@transport.request(:get, "/v1/Services/#{encode_path_segment(sid)}"))
    end

    def update(sid, **kwargs)
      MessagingService.from_hash(
        @transport.request(:post, "/v1/Services/#{encode_path_segment(sid)}",
                           form: form_params(SERVICE_FIELDS, kwargs))
      )
    end

    def delete(sid)
      @transport.request(:delete, "/v1/Services/#{encode_path_segment(sid)}")
      nil
    end

    # --- Sender-pool phone numbers (`/v1/Services/{ChatServiceSid}/PhoneNumbers`) ---

    # List the phone numbers in a Messaging Service's sender pool. Note the
    # spec declares only `Page`/`PageSize` here — no `PageToken`.
    #
    # @return [VoiceML::MessagingServicePhoneNumberList]
    def list_phone_numbers(chat_service_sid, page: nil, page_size: nil)
      params = {}
      params['Page'] = page unless page.nil?
      params['PageSize'] = page_size unless page_size.nil?
      MessagingServicePhoneNumberList.new(
        @transport.request(:get, "/v1/Services/#{encode_path_segment(chat_service_sid)}/PhoneNumbers",
                           params: params)
      )
    end

    # Add a phone number (by its `PN` sid) to a Messaging Service's sender
    # pool. HTTP 409 means the number is already in the pool.
    #
    # @return [VoiceML::MessagingServicePhoneNumber]
    def create_phone_number(chat_service_sid, phone_number_sid:)
      MessagingServicePhoneNumber.from_hash(
        @transport.request(:post, "/v1/Services/#{encode_path_segment(chat_service_sid)}/PhoneNumbers",
                           form: { 'PhoneNumberSid' => phone_number_sid })
      )
    end

    # @return [VoiceML::MessagingServicePhoneNumber]
    def fetch_phone_number(chat_service_sid, sid)
      MessagingServicePhoneNumber.from_hash(
        @transport.request(:get, "/v1/Services/#{encode_path_segment(chat_service_sid)}/PhoneNumbers/#{encode_path_segment(sid)}")
      )
    end

    # Remove a phone number from a Messaging Service's sender pool.
    #
    # @return [nil]
    def delete_phone_number(chat_service_sid, sid)
      @transport.request(:delete, "/v1/Services/#{encode_path_segment(chat_service_sid)}/PhoneNumbers/#{encode_path_segment(sid)}")
      nil
    end
  end
end
