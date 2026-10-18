# frozen_string_literal: true

require_relative 'base'
require_relative '../models/exports'

module VoiceML
  # Operations on `/Exports` — the account's daily usage archives.
  class ExportsResource < BaseResource
    # List the account's available archives, newest first.
    #
    # @return [VoiceML::ExportList]
    def list
      ExportList.from_hash(@transport.request(:get, path('Exports')))
    end

    # Download one day's archive. Like recording audio, the server may answer
    # with the bytes directly or with a 302 to a presigned object; redirects
    # are followed with credentials stripped and https -> http downgrades
    # refused.
    #
    # @param date [String] archive day, `YYYY-MM-DD`.
    # @return [VoiceML::ExportDownload]
    def download(date)
      status, content, headers = @transport.fetch_bytes(path('Exports', date, suffix: ''))
      content_type = headers['content-type']
      content_type = content_type.first if content_type.is_a?(Array)
      x_amz_id = headers['x-amz-id-2']
      ExportDownload.new(
        date: date,
        content: content,
        content_type: content_type || 'application/octet-stream',
        via_redirect: status == 200 && !x_amz_id.nil?
      )
    end
  end
end
