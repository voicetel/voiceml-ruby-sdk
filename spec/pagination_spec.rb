# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'pagination via each()' do
  let(:client) { VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY) }

  # ---------------------------------------------------------------------------
  # calls.each — two pages linked by next_page_uri with a PageToken
  # ---------------------------------------------------------------------------
  describe 'client.calls.each' do
    let(:call1) { { 'sid' => 'CA00000000000000000000000000000001', 'account_sid' => ACCOUNT_SID, 'status' => 'completed', 'direction' => 'outbound-api' } }
    let(:call2) { { 'sid' => 'CA00000000000000000000000000000002', 'account_sid' => ACCOUNT_SID, 'status' => 'completed', 'direction' => 'outbound-api' } }
    let(:call3) { { 'sid' => 'CA00000000000000000000000000000003', 'account_sid' => ACCOUNT_SID, 'status' => 'completed', 'direction' => 'outbound-api' } }

    it 'iterates across two pages, following next_page_uri verbatim' do
      stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
        .to_return(
          status: 200,
          body: {
            calls: [call1, call2],
            page: 0, page_size: 2,
            next_page_uri: "#{accounts_path('Calls')}?Page=1&PageToken=PAC0000000000000000000000000000001"
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
        .with(query: { 'Page' => '1', 'PageToken' => 'PAC0000000000000000000000000000001' })
        .to_return(
          status: 200,
          body: {
            calls: [call3],
            page: 1, page_size: 2,
            next_page_uri: nil
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      collected = []
      client.calls.each { |c| collected << c }

      expect(collected.length).to eq(3)
      expect(collected.map(&:sid)).to eq(%w[
        CA00000000000000000000000000000001
        CA00000000000000000000000000000002
        CA00000000000000000000000000000003
      ])
    end

    it 'never synthesises Page=N: page 2 is requested only via the PageToken' do
      stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
        .to_return(
          status: 200,
          body: {
            calls: [call1],
            page: 0, page_size: 1,
            next_page_uri: "#{accounts_path('Calls')}?Page=1&PageToken=PAC0000000000000000000000000000002"
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
        .with(query: { 'Page' => '1', 'PageToken' => 'PAC0000000000000000000000000000002' })
        .to_return(
          status: 200,
          body: { calls: [], page: 1, page_size: 1, next_page_uri: nil }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { |b| client.calls.each(&b) }.to yield_with_args(an_object_having_attributes(sid: call1['sid']))
    end

    it 'returns an Enumerator when called without a block' do
      stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
        .to_return(
          status: 200,
          body: {
            calls: [call1],
            page: 0, page_size: 2,
            next_page_uri: nil
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      enumerator = client.calls.each
      expect(enumerator).to be_a(Enumerator)
      expect(enumerator.to_a.length).to eq(1)
    end

    describe '#next_page' do
      it 'fetches the linked page and returns nil on the last page' do
        stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
          .to_return(
            status: 200,
            body: {
              calls: [call1],
              page: 0, page_size: 1,
              next_page_uri: "#{accounts_path('Calls')}?Page=3&PageToken=PAC0000000000000000000000000000009"
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
          .with(query: { 'Page' => '3', 'PageToken' => 'PAC0000000000000000000000000000009' })
          .to_return(
            status: 200,
            body: { calls: [call3], page: 3, page_size: 1, next_page_uri: nil }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        first = client.calls.list
        second = client.calls.next_page(first)
        expect(second).to be_a(VoiceML::CallList)
        expect(second.page).to eq(3)
        expect(client.calls.next_page(second)).to be_nil
      end
    end
  end

  # ---------------------------------------------------------------------------
  # conferences.each — two pages (2 + 1 = 3 total)
  # ---------------------------------------------------------------------------
  describe 'client.conferences.each' do
    let(:conf1) { { 'sid' => 'CF00000000000000000000000000000001', 'account_sid' => ACCOUNT_SID, 'friendly_name' => 'room-1', 'status' => 'in-progress' } }
    let(:conf2) { { 'sid' => 'CF00000000000000000000000000000002', 'account_sid' => ACCOUNT_SID, 'friendly_name' => 'room-2', 'status' => 'in-progress' } }
    let(:conf3) { { 'sid' => 'CF00000000000000000000000000000003', 'account_sid' => ACCOUNT_SID, 'friendly_name' => 'room-3', 'status' => 'completed' } }

    it 'iterates across two pages and yields every conference' do
      stub_request(:get, "#{base_url}#{accounts_path('Conferences')}")
        .to_return(
          status: 200,
          body: {
            conferences: [conf1, conf2],
            page: 0, page_size: 2,
            next_page_uri: "#{accounts_path('Conferences')}?Page=1&PageToken=PACF000000000000000000000000000001"
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "#{base_url}#{accounts_path('Conferences')}")
        .with(query: { 'Page' => '1', 'PageToken' => 'PACF000000000000000000000000000001' })
        .to_return(
          status: 200,
          body: {
            conferences: [conf3],
            page: 1, page_size: 2,
            next_page_uri: nil
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      collected = []
      client.conferences.each { |c| collected << c }

      expect(collected.length).to eq(3)
      expect(collected.map(&:sid)).to eq(%w[
        CF00000000000000000000000000000001
        CF00000000000000000000000000000002
        CF00000000000000000000000000000003
      ])
    end
  end

  # ---------------------------------------------------------------------------
  # recordings.each — the server requires PageToken on page 2+
  # ---------------------------------------------------------------------------
  describe 'client.recordings.each' do
    let(:rec1) { { 'sid' => 'RE00000000000000000000000000000001', 'account_sid' => ACCOUNT_SID, 'status' => 'completed' } }
    let(:rec2) { { 'sid' => 'RE00000000000000000000000000000002', 'account_sid' => ACCOUNT_SID, 'status' => 'completed' } }
    let(:rec3) { { 'sid' => 'RE00000000000000000000000000000003', 'account_sid' => ACCOUNT_SID, 'status' => 'completed' } }

    it 'iterates across two pages, sending the PageToken from next_page_uri' do
      stub_request(:get, "#{base_url}#{accounts_path('Recordings')}")
        .to_return(
          status: 200,
          body: {
            recordings: [rec1, rec2],
            page: 0, page_size: 2,
            next_page_uri: "#{accounts_path('Recordings')}?Page=1&PageToken=PARE000000000000000000000000000001"
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "#{base_url}#{accounts_path('Recordings')}")
        .with(query: { 'Page' => '1', 'PageToken' => 'PARE000000000000000000000000000001' })
        .to_return(
          status: 200,
          body: {
            recordings: [rec3],
            page: 1, page_size: 2,
            next_page_uri: nil
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      collected = []
      client.recordings.each { |r| collected << r }

      expect(collected.length).to eq(3)
      expect(collected.map(&:sid)).to eq(%w[
        RE00000000000000000000000000000001
        RE00000000000000000000000000000002
        RE00000000000000000000000000000003
      ])
    end
  end

  # ---------------------------------------------------------------------------
  # queues.each — two pages (2 + 1 = 3 total)
  # ---------------------------------------------------------------------------
  describe 'client.queues.each' do
    let(:q1) { { 'sid' => 'QU00000000000000000000000000000001', 'account_sid' => ACCOUNT_SID, 'friendly_name' => 'support', 'current_size' => 5 } }
    let(:q2) { { 'sid' => 'QU00000000000000000000000000000002', 'account_sid' => ACCOUNT_SID, 'friendly_name' => 'sales', 'current_size' => 3 } }
    let(:q3) { { 'sid' => 'QU00000000000000000000000000000003', 'account_sid' => ACCOUNT_SID, 'friendly_name' => 'billing', 'current_size' => 0 } }

    it 'iterates across two pages and yields every queue' do
      stub_request(:get, "#{base_url}#{accounts_path('Queues')}")
        .to_return(
          status: 200,
          body: {
            queues: [q1, q2],
            page: 0, page_size: 2,
            next_page_uri: "#{accounts_path('Queues')}?Page=1&PageToken=PAQU000000000000000000000000000001"
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "#{base_url}#{accounts_path('Queues')}")
        .with(query: { 'Page' => '1', 'PageToken' => 'PAQU000000000000000000000000000001' })
        .to_return(
          status: 200,
          body: {
            queues: [q3],
            page: 1, page_size: 2,
            next_page_uri: nil
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      collected = []
      client.queues.each { |q| collected << q }

      expect(collected.length).to eq(3)
      expect(collected.map(&:sid)).to eq(%w[
        QU00000000000000000000000000000001
        QU00000000000000000000000000000002
        QU00000000000000000000000000000003
      ])
    end
  end

  # ---------------------------------------------------------------------------
  # Single-page edge case — next_page_uri is nil from the start
  # ---------------------------------------------------------------------------
  describe 'single-page edge case' do
    it 'yields all items and stops when next_page_uri is nil on the first page' do
      call1 = { 'sid' => 'CA00000000000000000000000000000099', 'account_sid' => ACCOUNT_SID, 'status' => 'completed', 'direction' => 'inbound' }

      stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
        .to_return(
          status: 200,
          body: {
            calls: [call1],
            page: 0, page_size: 50,
            next_page_uri: nil
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      collected = []
      client.calls.each { |c| collected << c }

      expect(collected.length).to eq(1)
      expect(collected.first.sid).to eq('CA00000000000000000000000000000099')
    end
  end

  # ---------------------------------------------------------------------------
  # Lazy iteration — stopping early makes no further requests
  # ---------------------------------------------------------------------------
  describe 'lazy iteration' do
    it 'does not fetch page 2 when the consumer stops early' do
      call1 = { 'sid' => 'CA00000000000000000000000000000071', 'account_sid' => ACCOUNT_SID, 'status' => 'completed' }
      call2 = { 'sid' => 'CA00000000000000000000000000000072', 'account_sid' => ACCOUNT_SID, 'status' => 'completed' }

      first_page = stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
        .to_return(
          status: 200,
          body: {
            calls: [call1, call2],
            page: 0, page_size: 2,
            next_page_uri: "#{accounts_path('Calls')}?Page=1&PageToken=PACA000000000000000000000000000072"
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      second_page = stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
        .with(query: { 'Page' => '1', 'PageToken' => 'PACA000000000000000000000000000072' })
        .to_return(
          status: 200,
          body: { calls: [], page: 1, page_size: 2, next_page_uri: nil }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      client.calls.each { |_c| break }

      expect(first_page).to have_been_requested.once
      expect(second_page).not_to have_been_requested
    end
  end
end
