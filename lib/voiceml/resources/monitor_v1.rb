# frozen_string_literal: true

require_relative 'base'

require_relative '../models/monitor_v1'

module VoiceML
  # `client.monitor_alerts` — Monitor v1 Alerts (`/v1/Alerts`), on the
  # default host: failure events for calls and messaging delivery.
  #
  # The server serves a single page (`meta.next_page_url` is always `null`);
  # `next_page` follows the envelope verbatim regardless and returns `nil`
  # when there is no continuation.
  class MonitorAlertsResource
    include V1Pages
    include FieldMapping

    LIST_FIELDS = {
      'LogLevel'  => :log_level,
      'StartDate' => :start_date,
      'EndDate'   => :end_date,
      'PageSize'  => :page_size
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    # Return one page of alerts, narrowed by severity (`log_level:` `"error"`
    # or `"warning"`) and generation window (`start_date:` / `end_date:`,
    # `YYYY-MM-DD` or a full ISO-8601 timestamp). `page_size:` limits this
    # collection (default 50, capped at 1000 server-side).
    #
    # @return [VoiceML::MonitorAlertList]
    def list(**kwargs)
      MonitorAlertList.new(
        @transport.request(:get, '/v1/Alerts', params: form_params(LIST_FIELDS, kwargs))
      )
    end

    # Walk every page of `/v1/Alerts` and yield each alert, following the
    # envelope's `meta.next_page_url` verbatim. Returns an Enumerator when
    # called without a block; stopping early makes no further requests.
    #
    # @yield [VoiceML::MonitorAlert]
    # @return [Enumerator<VoiceML::MonitorAlert>] when no block given
    def each(**kwargs, &block)
      return enum_for(:each, **kwargs) unless block

      page = list(**kwargs)
      loop do
        page.alerts.each(&block)
        nxt = next_page(page)
        break if nxt.nil?

        page = nxt
      end
    end

    # Fetch one alert by sid, with the stored request/response detail when
    # the underlying event carries any.
    #
    # @return [VoiceML::MonitorAlert]
    def fetch(sid)
      MonitorAlert.from_hash(@transport.request(:get, "/v1/Alerts/#{encode_path_segment(sid)}"))
    end
  end
end
