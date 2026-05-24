# frozen_string_literal: true

require_relative 'base'
require_relative '../models/diagnostics'

module VoiceML
  # Account-scoped `/Notifications` compat stubs (always empty list; fetch returns 404).
  class NotificationsResource < BaseResource
    LIST_FIELDS = {
      'Page'          => :page,
      'PageSize'      => :page_size,
      'PageToken'     => :page_token,
      'Log'           => :log,
      'MessageDate'   => :message_date,
      'MessageDate<'  => :message_date_lt,
      'MessageDate>'  => :message_date_gt
    }.freeze

    # @return [VoiceML::NotificationsList]
    def list(**kwargs)
      NotificationsList.from_hash(
        @transport.request(:get, path('Notifications'),
                           params: form_params(LIST_FIELDS, kwargs))
      )
    end

    # @return [Hash]
    def get(notification_sid)
      @transport.request(:get, path('Notifications', notification_sid))
    end
  end
end
