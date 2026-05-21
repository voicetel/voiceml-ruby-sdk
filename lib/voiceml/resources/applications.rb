# frozen_string_literal: true

require_relative 'base'
require_relative '../models/applications'

module VoiceML
  # Operations on `/Applications` — persistent TwiML+callback bundles.
  class ApplicationsResource < BaseResource
    APPLICATION_FIELDS = {
      'FriendlyName'           => :friendly_name,
      'VoiceUrl'               => :voice_url,
      'VoiceMethod'            => :voice_method,
      'VoiceFallbackUrl'       => :voice_fallback_url,
      'VoiceFallbackMethod'    => :voice_fallback_method,
      'VoiceCallerIdLookup'    => :voice_caller_id_lookup,
      'StatusCallback'         => :status_callback,
      'StatusCallbackMethod'   => :status_callback_method,
      'StatusCallbackEvent'    => :status_callback_event
    }.freeze

    LIST_FIELDS = {
      'FriendlyName' => :friendly_name,
      'Page'         => :page,
      'PageSize'     => :page_size
    }.freeze

    # @return [VoiceML::Application]
    def create(**kwargs)
      Application.from_hash(
        @transport.request(:post, path('Applications'),
                           form: form_params(APPLICATION_FIELDS, kwargs))
      )
    end

    # @return [VoiceML::ApplicationList]
    def list(**kwargs)
      ApplicationList.from_hash(
        @transport.request(:get, path('Applications'), params: form_params(LIST_FIELDS, kwargs))
      )
    end

    # @return [VoiceML::Application]
    def get(application_sid)
      Application.from_hash(@transport.request(:get, path('Applications', application_sid)))
    end

    # @return [VoiceML::Application]
    def update(application_sid, **kwargs)
      Application.from_hash(
        @transport.request(:post, path('Applications', application_sid),
                           form: form_params(APPLICATION_FIELDS, kwargs))
      )
    end

    # @return [nil]
    def delete(application_sid)
      @transport.request(:delete, path('Applications', application_sid))
      nil
    end
  end
end
