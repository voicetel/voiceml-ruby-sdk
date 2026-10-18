# frozen_string_literal: true

# Official Ruby SDK for the VoiceML REST API.
#
# VoiceML is VoiceTel's outbound voice + AMD service with a Twilio-compatible
# REST surface (`https://voiceml.voicetel.com`). The wire shape, auth model,
# error codes, and pagination envelope follow the same conventions Twilio's
# documented API uses, so existing Twilio client patterns map across — but
# VoiceML issues its own credentials (AccountSid + VoiceML API key); swap the
# key before migrating.
#
# @example
#   require 'voiceml'
#
#   client = VoiceML::Client.new(account_sid: 'AC...', api_key: '...')
#   call = client.calls.create(
#     to: '+14155550100',
#     from: '+14155550101',
#     url: 'https://example.com/handler',
#     machine_detection: 'DetectMessageEnd'
#   )
#   puts call.sid, call.status
module VoiceML
end

require_relative 'voiceml/version'
require_relative 'voiceml/errors'
require_relative 'voiceml/transport'
require_relative 'voiceml/request_validator'
require_relative 'voiceml/client'

# Standalone models for surfaces without a first-class client.* getter yet;
# they remain decodable Ruby classes for response-shape conformance and
# migration tooling. Resource files require their own models.
require_relative 'voiceml/models/user_defined_messages'
require_relative 'voiceml/models/notifications'
require_relative 'voiceml/models/assistants_v1'
