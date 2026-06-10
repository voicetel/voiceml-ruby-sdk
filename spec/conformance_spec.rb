# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'set'

# Twilio response-shape conformance tests (#330 Phase C). Mirrors the
# Go (voiceml-go-sdk@d6ac75c), Python (voiceml-python-sdk), TypeScript
# (voiceml-node-sdk@a11b0a1), Java (voiceml-java-sdk@9178659), C#
# (voiceml-csharp-sdk@087679f), and PHP (voiceml-php-sdk@4267511)
# harnesses: load 132 canonical Twilio response examples from
# callBroadcast's cmd/twilio-conformance-fixtures, run each through
# the matching SDK model's `from_hash()` factory, assert key fields.
# SKIPPED unless VOICEML_CONFORMANCE_FIXTURES env points at the corpus.
#
# Ruby has no compile-time types, so the "strictness" here is purely
# the post-decode assertions on the model's attr_reader values. A
# nil/empty sid trips immediately. The cycle is `Klass.from_hash(...)`
# then `instance.sid`; the SDK's exception surface (NoMethodError on
# nil-cascade, KeyError on missing wrapper key) catches model
# structural breakage.
#
# Run:
#
#   VOICEML_CONFORMANCE_FIXTURES=/path/to/callBroadcast/cmd/twilio-conformance-fixtures/fixtures \
#     bundle exec rspec spec/conformance_spec.rb

FIXTURES_ENV = 'VOICEML_CONFORMANCE_FIXTURES'

SKIP_OPS = %w[
  ListCallEvent
  ListCallNotification
  FetchCallNotification
  ListNotification
  FetchNotification
  CreateUserDefinedMessage
  CreateMessage
  FetchMessage
  ListMessage
  UpdateMessage
].to_set

def load_conformance_entries
  root = ENV[FIXTURES_ENV]
  return [] if root.nil? || root.empty?

  index_path = File.join(root, 'index.json')
  return [] unless File.exist?(index_path)

  entries = JSON.parse(File.read(index_path))
  entries.map do |entry|
    {
      op_id: entry['operation_id'],
      resource: entry['resource'],
      example: entry['example_name'],
      path: File.join(root, entry['file'])
    }
  end
end

# Resolve an operation_id to the SDK model factory and the field
# assertions to run after decode. Returns nil for skipped operations
# (unmodelled Messages, compat-stub notifications/events,
# UserDefinedMessage).
def conformance_target(op_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  case op_id
  when 'CreateCall', 'FetchCall', 'UpdateCall'
    [VoiceML::Call, %w[sid account_sid]]
  when 'ListCall'
    [VoiceML::CallList, %w[uri]]
  when 'FetchConference', 'UpdateConference'
    [VoiceML::Conference, %w[sid account_sid]]
  when 'ListConference'
    [VoiceML::ConferenceList, %w[uri]]
  when 'CreateParticipant', 'FetchParticipant', 'UpdateParticipant'
    [VoiceML::Participant, %w[call_sid conference_sid]]
  when 'ListParticipant'
    [VoiceML::ParticipantList, %w[uri]]
  when 'CreateQueue', 'FetchQueue', 'UpdateQueue'
    [VoiceML::Queue, %w[sid account_sid]]
  when 'ListQueue'
    [VoiceML::QueueList, %w[uri]]
  when 'FetchMember', 'UpdateMember'
    [VoiceML::QueueMember, %w[call_sid]]
  when 'ListMember'
    [VoiceML::QueueMemberList, %w[uri]]
  when 'CreateApplication', 'FetchApplication', 'UpdateApplication'
    [VoiceML::Application, %w[sid account_sid]]
  when 'ListApplication'
    [VoiceML::ApplicationList, %w[uri]]
  when 'CreateCallRecording', 'FetchCallRecording', 'UpdateCallRecording',
       'FetchRecording', 'FetchConferenceRecording', 'UpdateConferenceRecording'
    [VoiceML::Recording, %w[sid account_sid]]
  when 'ListCallRecording', 'ListRecording', 'ListConferenceRecording'
    [VoiceML::RecordingList, %w[uri]]
  when 'CreateIncomingPhoneNumber', 'CreateIncomingPhoneNumberLocal',
       'CreateIncomingPhoneNumberMobile', 'CreateIncomingPhoneNumberTollFree',
       'FetchIncomingPhoneNumber', 'UpdateIncomingPhoneNumber'
    [VoiceML::IncomingPhoneNumber, %w[sid account_sid]]
  when 'ListIncomingPhoneNumber', 'ListIncomingPhoneNumberLocal',
       'ListIncomingPhoneNumberMobile', 'ListIncomingPhoneNumberTollFree'
    [VoiceML::IncomingPhoneNumberList, %w[uri]]
  # Stream / SiprecSession / CallTranscription Create/Update fixtures don't
  # emit api_version. Same drift the TS harness fixed-forward — Ruby's
  # attr_reader returns nil for the missing field, which the harness
  # ignores by simply not asserting on it. sid/account_sid/call_sid asserted.
  when 'CreateStream', 'UpdateStream'
    [VoiceML::Stream, %w[sid account_sid call_sid]]
  when 'CreateSiprec', 'UpdateSiprec'
    [VoiceML::SiprecSession, %w[sid account_sid call_sid]]
  when 'CreateRealtimeTranscription', 'UpdateRealtimeTranscription'
    [VoiceML::CallTranscription, %w[sid account_sid call_sid]]
  end
end

RSpec.describe 'Twilio response-shape conformance' do
  entries = load_conformance_entries

  if entries.empty?
    it 'skipped when VOICEML_CONFORMANCE_FIXTURES is not set' do
      skip "#{FIXTURES_ENV} not set or index.json missing"
    end
  else
    entries.each do |entry|
      it "#{entry[:resource]}/#{entry[:op_id]}/#{entry[:example]}" do
        if SKIP_OPS.include?(entry[:op_id])
          skip "no SDK model for #{entry[:op_id]}"
        end

        target = conformance_target(entry[:op_id])
        if target.nil?
          raise "conformance harness: no mapping for operation_id=#{entry[:op_id]} " \
                "(fixture=#{entry[:path]}). Add a case or extend SKIP_OPS."
        end

        klass, required_fields = target
        body = JSON.parse(File.read(entry[:path]))
        instance = klass.from_hash(body)

        expect(instance).not_to be_nil, "#{klass}.from_hash returned nil"
        required_fields.each do |field|
          value = instance.public_send(field.to_sym)
          expect(value).not_to be_nil, "#{klass}.#{field} is nil"
          expect(value).not_to(eq(''), "#{klass}.#{field} is empty string")
        end
      end
    end
  end
end
