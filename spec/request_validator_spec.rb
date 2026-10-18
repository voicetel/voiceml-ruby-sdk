# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VoiceML::RequestValidator do
  let(:api_key) { 'test-api-key-0123456789' }
  let(:validator) { described_class.new(api_key) }

  describe 'form-post signature (vector 1)' do
    let(:url) { 'https://example.com/voice/answer?case=1' }
    let(:params) do
      {
        'CallSid' => 'CA0123456789abcdef0123456789abcdef',
        'From' => '+14155550100',
        'To' => '+14155550101',
        'Digits' => '1234',
        'AccountSid' => 'ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
      }
    end

    it 'validates the reference signature' do
      expect(validator.valid?(url, params, 'RweoLyWqNC7H8+MLXPb7EPz18OI=')).to be(true)
    end

    it 'accepts the same signature when the URL carries the default port' do
      expect(validator.valid?('https://example.com:443/voice/answer?case=1', params,
                              'RweoLyWqNC7H8+MLXPb7EPz18OI=')).to be(true)
    end

    it 'accepts the signature computed over the :443 URL when validating the port-less URL' do
      expect(validator.valid?(url, params, 'xE0r2wPa6d1ktQeCFpPyINmTNYg=')).to be(true)
    end
  end

  describe 'repeated form keys (vector 3)' do
    it 'signs each key+value pair in received order' do
      params = [['To', '+14155550101'], ['Event', 'answered'], ['Event', 'initiated']]
      expect(validator.valid?('https://example.com/hook', params,
                              'jCnpBgyg45aZYwUie5fmq4EYUic=')).to be(true)
    end
  end

  describe 'GET signature (vector 4)' do
    it 'signs the URL alone' do
      url = 'https://example.com/voice/answer?CallSid=CA0123456789abcdef0123456789abcdef&From=%2B14155550100'
      expect(validator.valid?(url, [], '9I4odWBHhF7TMIkIrNtPEPjD9fU=', method: 'GET')).to be(true)
    end
  end

  describe 'rejections' do
    let(:url) { 'https://example.com/voice/answer?case=1' }
    let(:params) { { 'CallSid' => 'CA0123456789abcdef0123456789abcdef', 'Digits' => '1234' } }

    it 'rejects a tampered parameter value' do
      expect(validator.valid?(url, params.merge('Digits' => '9999'),
                              'RweoLyWqNC7H8+MLXPb7EPz18OI=')).to be(false)
    end

    it 'rejects a signature made with the wrong key' do
      other = described_class.new('wrong-key')
      signature = other.signature(url, params)
      expect(validator.valid?(url, params, signature)).to be(false)
    end

    it 'rejects a malformed signature without raising' do
      expect(validator.valid?(url, params, 'not-base64!!!')).to be(false)
    end
  end

  describe '#compute' do
    it 'round-trips through valid?' do
      url = 'https://example.com/voice/answer'
      params = { 'CallSid' => 'CA0123456789abcdef0123456789abcdef' }
      expect(validator.valid?(url, params, validator.signature(url, params))).to be(true)
    end
  end
end
