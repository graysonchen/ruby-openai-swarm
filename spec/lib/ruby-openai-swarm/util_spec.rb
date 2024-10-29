require 'spec_helper'
require 'ruby-openai-swarm/util'

RSpec.describe OpenAISwarm::Util do


  describe ".merge_chunk" do
    let(:completion) do
      [
        {"id"=>"gen-1730200729-x", "provider"=>"OpenAI", "model"=>"openai/gpt-4o-mini", "object"=>"chat.completion.chunk", "created"=>1730200729, "choices"=>[{"index"=>0, "delta"=>{"tool_calls"=>[{"index"=>0, "function"=>{"arguments"=>"{\""}, "type"=>"function"}]}, "logprobs"=>nil, "finish_reason"=>nil}], "system_fingerprint"=>"fp_xxxxxxxx"},
        {"id"=>"gen-1730200729-x", "provider"=>"OpenAI", "model"=>"openai/gpt-4o-mini", "object"=>"chat.completion.chunk", "created"=>1730200729, "choices"=>[{"index"=>0, "delta"=>{"tool_calls"=>[{"index"=>0, "function"=>{"arguments"=>"location"}, "type"=>"function"}]}, "logprobs"=>nil, "finish_reason"=>nil}], "system_fingerprint"=>"fp_xxxxxxxx"},
        {"id"=>"gen-1730200729-x", "provider"=>"OpenAI", "model"=>"openai/gpt-4o-mini", "object"=>"chat.completion.chunk", "created"=>1730200729, "choices"=>[{"index"=>0, "delta"=>{"tool_calls"=>[{"index"=>0, "function"=>{"arguments"=>"\":\""}, "type"=>"function"}]}, "logprobs"=>nil, "finish_reason"=>nil}], "system_fingerprint"=>"fp_xxxxxxxx"},
        {"id"=>"gen-1730200729-x", "provider"=>"OpenAI", "model"=>"openai/gpt-4o-mini", "object"=>"chat.completion.chunk", "created"=>1730200729, "choices"=>[{"index"=>0, "delta"=>{"tool_calls"=>[{"index"=>0, "function"=>{"arguments"=>"London"}, "type"=>"function"}]}, "logprobs"=>nil, "finish_reason"=>nil}], "system_fingerprint"=>"fp_xxxxxxxx"},
        {"id"=>"gen-1730200729-x", "provider"=>"OpenAI", "model"=>"openai/gpt-4o-mini", "object"=>"chat.completion.chunk", "created"=>1730200729, "choices"=>[{"index"=>0, "delta"=>{"tool_calls"=>[{"index"=>0, "function"=>{"arguments"=>"\"}"}, "type"=>"function"}]}, "logprobs"=>nil, "finish_reason"=>nil}], "system_fingerprint"=>"fp_xxxxxxxx"},
        {"id"=>"gen-1730200729-x", "provider"=>"OpenAI", "model"=>"openai/gpt-4o-mini", "object"=>"chat.completion.chunk", "created"=>1730200729, "choices"=>[{"index"=>0, "delta"=>{"role"=>"assistant", "content"=>""}, "finish_reason"=>"tool_calls", "logprobs"=>nil}], "system_fingerprint"=>"fp_xxxxxxxx"},
      ]
    end
    let(:message_template) { OpenAISwarm::Util.message_template('agent_name')}

    it do
      completion.each do |chunk|
        delta = chunk.dig('choices', 0, 'delta')
        if delta['role'] == "assistant"
          delta['sender'] = 'active_agent.name'
        end
        delta.delete('role')
        delta.delete('sender')
        OpenAISwarm::Util.merge_chunk(message_template, delta)
      end

      expect(message_template).to eq({
        "content" => "",
        "sender" => "agent_name",
        "role" => "assistant",
        "function_call" => nil,
        "tool_calls" => {
          0 => {
            "function" => { "arguments" => "{\"location\":\"London\"}", "name" => "" },
            "id" => "",
            "type" => "function"
          }
        }
      })
    end
  end

  describe '.function_to_json' do
    let(:mock_method) do
      instance_double(Method,
        name: 'test_function',
        parameters: [[:req, :param1], [:opt, :param2], [:keyreq, :param3]]
      )
    end

    let(:mock_function) do
      instance_double('Function',
        target_method: mock_method,
        description: 'This is a test function'
      )
    end

    subject(:result) { described_class.function_to_json(mock_function) }

    it 'returns a hash with the correct structure' do
      expect(result).to be_a(Hash)
      expect(result[:type]).to eq('function')
    end

    it 'includes the correct function name and description' do
      expect(result[:function][:name]).to eq('test_function')
      expect(result[:function][:description]).to eq('This is a test function')
    end

    it 'correctly structures the parameters' do
      parameters = result[:function][:parameters]
      expect(parameters[:type]).to eq('object')
      expect(parameters[:required]).to contain_exactly('param1', 'param3')
    end

    it 'sets the correct type for each parameter' do
      properties = result[:function][:parameters][:properties]
      expect(properties[:param1][:type]).to eq('string')
      expect(properties[:param2][:type]).to eq('string')
      expect(properties[:param3][:type]).to eq('string')
    end
  end
end
