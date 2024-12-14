require 'spec_helper'
require 'ruby-openai-swarm/util'

RSpec.describe OpenAISwarm::Util do
  # Sample messages for testing
  let(:sample_messages) do
    [
      {
        :role=>"system",
        :content=>"You are a helpful agent."
      },
      {
        "role"=>"user",
        "content"=>"Tell me the weather in New York and the latest news headlines."
      },
      {
        "content"=>"",
        "sender"=>"Agent",
        "role"=>"assistant",
        "function_call"=>nil,
        "tool_calls"=>[
          {
            "function"=>{
              "arguments"=>"{\"location\": \"New York\"}",
              "name"=>"get_weather"
            },
            "id"=>"call_t5GEhNxjlLk5eYLPSlS3Soel",
            "type"=>"function"
          },
          {
            "function"=>{
              "arguments"=>"{\"category\": \"world\"}",
              "name"=>"get_news"
            },
            "id"=>"call_E8mXevyZMzo5Ns2XrF7Yg8wg",
            "type"=>"function"
          }
        ]
      },
      {
        "role"=>"tool",
        "tool_call_id"=>"call_t5GEhNxjlLk5eYLPSlS3Soel",
        "tool_name"=>"get_weather",
        "content"=>"{'temp':67, 'unit':'F'}"
      },
      {
        "role"=>"tool",
        "tool_call_id"=>"call_E8mXevyZMzo5Ns2XrF7Yg8wg",
        "tool_name"=>"get_news",
        "content"=>"Breakthrough in Quantum Computing"
      }
    ]
  end

  context 'when tool_names is empty' do
    it 'returns messages unchanged' do
      result = described_class.clean_message_tools(sample_messages, [])
      expect(result).to eq(sample_messages)
    end
  end

  context 'when removing get_weather tool' do
    it 'removes get_weather tool call and its response' do
      result = described_class.clean_message_tools(sample_messages, ['get_weather'])

      # Check the structure of the result
      expect(result.length).to eq(4)

      # Check assistant message
      assistant_message = result.find { |msg| msg['role'] == 'assistant' }
      expect(assistant_message['tool_calls'].length).to eq(1)
      expect(assistant_message['tool_calls'].first['function']['name']).to eq('get_news')

      # Check that get_weather tool response is removed
      tool_messages = result.select { |msg| msg['role'] == 'tool' }
      expect(tool_messages.length).to eq(1)
      expect(tool_messages.first['tool_name']).to eq('get_news')
    end
  end

  context 'when removing get_news tool' do
    it 'removes get_news tool call and its response' do
      result = described_class.clean_message_tools(sample_messages, ['get_news'])

      # Check the structure of the result
      expect(result.length).to eq(4)

      # Check assistant message
      assistant_message = result.find { |msg| msg['role'] == 'assistant' }
      expect(assistant_message['tool_calls'].length).to eq(1)
      expect(assistant_message['tool_calls'].first['function']['name']).to eq('get_weather')

      # Check that get_news tool response is removed
      tool_messages = result.select { |msg| msg['role'] == 'tool' }
      expect(tool_messages.length).to eq(1)
      expect(tool_messages.first['tool_name']).to eq('get_weather')
    end
  end

  context 'when removing both get_weather and get_news tools' do
    it 'removes all tool calls and tool responses' do
      result = described_class.clean_message_tools(sample_messages, ['get_weather', 'get_news'])
      # Check the structure of the result
      expect(result.length).to eq(2)
      # Check that only system and user messages remain
      expect(result.map { |msg| msg['role'] }).to contain_exactly('system', 'user')
    end
  end

  context 'when messages contain multiple tool calls' do
    let(:complex_messages) do
      sample_messages + [
        {
          role: "assistant",
          tool_calls: [
            {
              function: {
                name: "additional_tool"
              },
              id: "call_additional_xxxxxx"
            }
          ]
        },
        {
          role: "tool",
          tool_call_id: "call_additional_xxxxxx",
          tool_name: "additional_tool",
          content: "Additional tool response"
        }
      ]
    end

    it 'handles additional tool calls correctly' do
      result = described_class.clean_message_tools(complex_messages, ['get_weather', 'get_news'])
      # Check the structure of the result
      expect(result.length).to eq(4)

      # Check that only system, user, and additional tool messages remain
      roles = result.map { |msg| msg['role'] }
      expect(roles).to contain_exactly('system', 'user', 'assistant', 'tool')

      # Check the remaining assistant message
      additional_assistant = result.find { |msg| msg['role'] == 'assistant' }
      expect(additional_assistant['tool_calls'].first['function']['name']).to eq('additional_tool')
    end
  end
end
