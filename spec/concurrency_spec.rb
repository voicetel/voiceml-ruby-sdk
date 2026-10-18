# frozen_string_literal: true

require 'spec_helper'
require 'socket'

RSpec.describe 'concurrent use of one client', :network do
  # Real sockets are needed to reproduce the interleaving webmock cannot.
  around do |example|
    WebMock.allow_net_connect!
    example.run
  ensure
    WebMock.disable_net_connect!
  end

  # Regression: one shared Net::HTTP connection previously served every
  # request while the mutex covered only connection lookup, so concurrent
  # threads read each other's responses. The transport now serialises the
  # whole request/response exchange per origin connection (and keeps one
  # connection per origin), which this spec exercises against a real
  # local keep-alive TCP server rather than webmock's single-threaded stubs.
  let(:threads) { 4 }
  let(:per_thread) { 25 }

  def start_echo_server
    server = TCPServer.new('127.0.0.1', 0)
    accept = Thread.new do
      loop do
        sock = server.accept
        Thread.new(sock) do |s|
          loop do
            line = s.gets or break
            path = line.split[1]
            while (h = s.gets) && h != "\r\n"; end
            sid = path[%r{Calls/([^/.]+)\.json}, 1]
            body = JSON.generate('sid' => sid, 'status' => 'completed',
                                 'to' => '+14155550101', 'from' => '+14155550100')
            s.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" \
                    "Content-Length: #{body.bytesize}\r\nConnection: keep-alive\r\n\r\n#{body}")
          end
        rescue StandardError
          nil
        ensure
          s.close unless s.closed?
        end
      end
    end
    [server, accept]
  end

  it 'never hands one thread the response of another' do
    server, accept = start_echo_server
    port = server.addr[1]
    client = VoiceML::Client.new(account_sid: 'AC' + 'a' * 32, api_key: 'k',
                                 base_url: "http://127.0.0.1:#{port}", max_retries: 0)
    mismatches = Queue.new
    errors = Queue.new
    workers = Array.new(threads) do |t|
      Thread.new do
        per_thread.times do |i|
          want = "CA#{t}#{format('%02d', i)}#{'a' * 26}"
          got = client.calls.get(want).sid
          mismatches << [want, got] unless got == want
        rescue StandardError => e
          errors << "#{e.class}: #{e.message[0, 80]}"
        end
      end
    end
    workers.each(&:join)

    expect(errors.size).to eq(0), "errors: #{Array.new(errors.size) { errors.pop }.first(3)}"
    expect(mismatches.size).to eq(0), "cross-thread responses: #{Array.new(mismatches.size) { mismatches.pop }.first(3)}"
  ensure
    accept.kill
    server.close unless server.closed?
  end
end
