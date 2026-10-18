# frozen_string_literal: true

require_relative 'base'
require_relative '../models/accounts'

module VoiceML
  # Operations on `/2010-04-01/Accounts/{Sid}` — the account record itself and
  # its balance. `client.accounts` reads the authenticated account; `fetch`/
  # `update` accept any AccountSid the credentials can see (in practice the
  # credential's own account).
  class AccountsResource < BaseResource
    UPDATE_FIELDS = {
      'FriendlyName'        => :friendly_name,
      'VoiceUrl'            => :voice_url,
      'VoiceMethod'         => :voice_method,
      'VoiceFallbackUrl'    => :voice_fallback_url,
      'VoiceFallbackMethod' => :voice_fallback_method,
      'SttFsVendor'         => :stt_fs_vendor,
      'SttHttpUrl'          => :stt_http_url,
      'SttHttpToken'        => :stt_http_token,
      'TtsHttpUrl'          => :tts_http_url,
      'TtsHttpToken'        => :tts_http_token,
      'TtsEngineName'       => :tts_engine_name,
      'TtsDefaultVoice'     => :tts_default_voice,
      'TtsDefaultLanguage'  => :tts_default_language,
      'AwsBucket'           => :aws_bucket,
      'AwsRegion'           => :aws_region,
      'AwsPrefix'           => :aws_prefix,
      'AwsAccessKeyId'      => :aws_access_key_id,
      'AwsSecretAccessKey'  => :aws_secret_access_key,
      'AwsKmsKeyId'         => :aws_kms_key_id,
      'AllowCidr'           => :allow_cidr
    }.freeze

    # Fetch the account record. Omit `sid` to read the authenticated account.
    #
    # @return [VoiceML::Account]
    def fetch(sid = @transport.account_sid)
      Account.from_hash(
        @transport.request(:get, "/2010-04-01/Accounts/#{encode_path_segment(sid)}.json")
      )
    end

    # Update the account record. A concurrent modification surfaces as
    # `VoiceML::ConflictError` (HTTP 409 / code 20409 — optimistic locking).
    #
    # @return [VoiceML::Account]
    def update(sid = @transport.account_sid, **kwargs)
      Account.from_hash(
        @transport.request(:post, "/2010-04-01/Accounts/#{encode_path_segment(sid)}.json",
                           form: form_params(UPDATE_FIELDS, kwargs))
      )
    end

    # Fetch the account balance.
    #
    # @return [VoiceML::Balance]
    def fetch_balance
      Balance.from_hash(@transport.request(:get, path('Balance')))
    end

    # Rotate the account's API key (`POST /Accounts/{Sid}/RotateKey.json`,
    # no request body). The previous key stops working immediately. The new
    # key rides the returned {VoiceML::AccountWithKey} as `api_key` — no
    # read endpoint exposes it, so store it right away. It never appears in
    # the model's `inspect` / `to_s`.
    #
    # @return [VoiceML::AccountWithKey]
    def rotate_key(sid = @transport.account_sid)
      AccountWithKey.from_hash(
        @transport.request(:post, "/2010-04-01/Accounts/#{encode_path_segment(sid)}/RotateKey.json")
      )
    end
  end
end
