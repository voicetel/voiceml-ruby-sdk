# frozen_string_literal: true

require 'spec_helper'
require 'set'

# Discovers endpoint methods from the actual public resource graph, including
# the bound Assistant/Knowledge/Session and Conversation Service factories.
# The schema is used only for independent assertions and input values; SDK
# field maps are never used to derive the expected operation or wire keys.
module PublicContract
  class Captured < StandardError; end

  module_function

  def resolve(value, spec)
    value.key?('$ref') ? resolve(spec.dig(*value['$ref'].delete_prefix('#/').split('/')), spec) : value
  end

  def snake(name)
    name.sub(/>\z/, '_gt').sub(/<\z/, '_lt')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('.-', '__').downcase.to_sym
  end

  def operations(spec)
    spec['paths'].flat_map do |path, item|
      item.filter_map do |verb, operation|
        next unless %w[get post put patch delete head].include?(verb)

        params = (item.fetch('parameters', []) + operation.fetch('parameters', [])).map { |p| resolve(p, spec) }
        content = resolve(operation.fetch('requestBody', {}), spec).fetch('content', {})
        bodies = content.transform_values { |media| resolve(media.fetch('schema', {}), spec) }
        regex = Regexp.new('\A' + path.split(/(\{[^}]+\})/).map { |s| s.start_with?('{') ? '[^/]+' : Regexp.escape(s) }.join + '\z')
        { path: path, verb: verb.upcase, operation: operation, params: params, bodies: bodies, regex: regex }
      end
    end
  end

  def sample(schema)
    return schema['enum'].first if schema['enum'] && !schema['enum'].empty?

    case Array(schema['type']).first
    when 'integer', 'number' then 1
    when 'boolean' then false
    when 'array' then [sample(schema.fetch('items', { 'type' => 'string' }))]
    when 'object' then {}
    else 'value'
    end
  end

  def inputs(ops, spec)
    ops.each_with_object({}) do |op, out|
      op[:params].each do |param|
        out[snake(param['name'])] = sample(resolve(param.fetch('schema', {}), spec)) unless param['in'] == 'path'
      end
      op[:bodies].each_value do |body|
        body.fetch('properties', {}).each { |key, schema| out[snake(key)] = sample(resolve(schema, spec)) }
      end
    end.merge(to: '+14155550100', from: '+14155550101', body: 'hello', method: 'POST',
              voice_method: 'POST', sms_method: 'POST', status_callback_method: 'POST')
  end

  def resource?(object)
    object.class.name&.start_with?('VoiceML::') && object.class.name.match?(/(?:Resource|Scope|Product)\z/)
  end

  # Unknown kwargs are rejected by the public API. Remove only explicitly
  # rejected inputs and retry the invocation; every accepted field is then
  # checked against the independent spec, including optional fields.
  def invoke(object, method, args, kwargs)
    bound = object.method(method)
    takes_block = bound.parameters.any? { |kind, _| %i[block blockreq].include?(kind) }
    loop do
      if takes_block
        return object.public_send(method, *args, **kwargs) { |_item| }
      end
      return object.public_send(method, *args, **kwargs)
    rescue ArgumentError => e
      unknown = e.message[/\Aunknown keyword\(s\): (.*?);/, 1]
      raise unless unknown

      keys = unknown.scan(/:([a-z_][a-z_0-9]*)/).flatten.map(&:to_sym)
      raise if keys.empty? || (keys & kwargs.keys).empty?

      kwargs = kwargs.reject { |key, _value| keys.include?(key) }
    end
  end

  def walk(client, values)
    queue = [['client', client]]
    seen = Set.new
    until queue.empty?
      label, object = queue.shift
      next unless seen.add?(object.object_id)

      object.instance_variables.each do |ivar|
        child = object.instance_variable_get(ivar)
        queue << ["#{label}.#{ivar.to_s.delete_prefix('@')}", child] if resource?(child)
      end
      next if object.equal?(client)

      object.class.public_instance_methods(false).sort.each do |name|
        next if %i[inspect to_s].include?(name)

        method = object.method(name)
        parameters = method.parameters
        # No-argument accessors are already represented by the object graph.
        next if parameters.empty? && object.instance_variable_defined?("@#{name}") && resource?(object.instance_variable_get("@#{name}"))

        args = parameters.filter_map.with_index { |(type, _key), index| "P#{index}" if type == :req }
        keywords = parameters.each_with_object({}) do |(type, key), out|
          out[key] = values.fetch(key, 'value') if %i[keyreq key].include?(type)
        end
        keywords.merge!(values) if parameters.any? { |type, _key| type == :keyrest }
        variants = [args]
        # Optional positional identifiers bind factory scopes and account SIDs.
        variants << args + ['P0'] if parameters.any? { |type, key| type == :opt && key != :payload }
        variants.each do |positional|
          yield "#{label}.#{name}"
          begin
            result = invoke(object, name, positional, keywords)
            queue << ["#{label}.#{name}(#{positional.join(',')})", result] if resource?(result)
          rescue Captured
            # Expected: capture stops before any request can reach the network.
          end
        end
      end
    end
  end
end

RSpec.describe 'vendored public OpenAPI contract' do
  it 'covers all 333 operations with spec methods, paths, fields, required inputs, hosts and auth' do
    spec = JSON.parse(File.read(File.join(__dir__, 'fixtures/voiceml-openapi.json')))
    ops = PublicContract.operations(spec)
    records = []
    current = nil
    %i[request request_raw fetch_bytes].each do |kind|
      allow_any_instance_of(VoiceML::Transport).to receive(kind) do |_transport, *args, **options|
        verb, path = kind == :fetch_bytes ? [:get, args.first] : args
        records << { call: current, verb: verb.to_s.upcase, path: path, options: options, kind: kind }
        raise PublicContract::Captured
      end
    end
    client = VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY)
    PublicContract.walk(client, PublicContract.inputs(ops, spec)) { |name| current = name }
    covered = Set.new
    shared_hosts = Hash.new { |h, k| h[k] = Set.new }
    records.each do |record|
      uri = URI.parse(record[:path])
      candidates = ops.select { |op| op[:verb] == record[:verb] && op[:regex].match?(uri.path) }
      expect(candidates).not_to be_empty, "non-spec request: #{record}"
      op = candidates.min_by { |candidate| candidate[:path].count('{') }
      covered << [op[:verb], op[:path]]
      options = record[:options]
      query = (options[:params] || {}).keys.map(&:to_s)
      declared_query = op[:params].select { |p| p['in'] == 'query' }.map { |p| p['name'] }
      expect(query.sort).to eq(declared_query.sort), "query fields for #{record[:call]} (#{op[:operation]['operationId']})"
      format = options[:json] ? 'application/json' : 'application/x-www-form-urlencoded'
      body = options[:json] || options[:form] || {}
      schema = op[:bodies].fetch(format, {})
      expect(body.keys.map(&:to_s).sort).to eq(schema.fetch('properties', {}).keys.sort), "body fields for #{record[:call]}"
      expect(schema.fetch('required', []) - body.keys.map(&:to_s)).to be_empty
      expect(options.fetch(:auth, true)).to eq(op[:operation].fetch('security', spec.fetch('security', [])) != [])
      host = options.fetch(:base_url, client.base_url)
      tags = op[:operation].fetch('tags', [])
      expected = []
      expected << 'https://conversations.voicetel.com' if tags.any? { |t| t.start_with?('ConversationsV1') }
      expected << 'https://messaging.voicetel.com' if tags.include?('MessagingV1Service')
      expected << client.base_url if expected.empty?
      expect(expected).to include(host), "host for #{record[:call]}: #{host}"
      shared_hosts[[op[:verb], op[:path]]] << host if expected.length == 2
    end
    missing = ops.reject { |op| covered.include?([op[:verb], op[:path]]) }.map { |op| op[:operation]['operationId'] }
    expect(missing).to eq([]), "missing operations: #{missing.join(', ')}"
    expect(covered.length).to eq(333)
    shared_hosts.each_value do |hosts|
      expect(hosts).to eq(Set['https://conversations.voicetel.com', 'https://messaging.voicetel.com'])
    end
  end
end
