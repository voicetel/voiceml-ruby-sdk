# frozen_string_literal: true

require_relative 'base'
require_relative '../models/usage_records'

module VoiceML
  # Operations on `/Usage/Records` — usage buckets over the account, with the
  # nine fixed windows (`AllTime`, `Daily`, `LastMonth`, `Monthly`,
  # `ThisMonth`, `Today`, `Yearly`, `Yesterday`) the API offers.
  class UsageRecordsResource < BaseResource
    LIST_FIELDS = {
      'Category'          => :category,
      'StartDate'         => :start_date,
      'EndDate'           => :end_date,
      'IncludeSubaccounts' => :include_subaccounts,
      'Page'              => :page,
      'PageSize'          => :page_size,
      'PageToken'         => :page_token
    }.freeze

    WINDOWS = {
      all_time: 'AllTime',
      daily: 'Daily',
      last_month: 'LastMonth',
      monthly: 'Monthly',
      this_month: 'ThisMonth',
      today: 'Today',
      yearly: 'Yearly',
      yesterday: 'Yesterday'
    }.freeze

    # @return [VoiceML::UsageRecordList]
    def list(**kwargs)
      UsageRecordList.from_hash(
        @transport.request(:get, path('Usage', 'Records'),
                           params: form_params(LIST_FIELDS, kwargs))
      )
    end

    WINDOWS.each do |ruby_name, segment|
      # @!method list_all_time(**kwargs)
      # @return [VoiceML::UsageRecordList]
      define_method("list_#{ruby_name}") do |**kwargs|
        UsageRecordList.from_hash(
          @transport.request(:get, path('Usage', 'Records', segment),
                             params: form_params(LIST_FIELDS, kwargs))
        )
      end
    end
  end
end
