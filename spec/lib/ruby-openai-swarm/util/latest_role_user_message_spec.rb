require 'spec_helper'

RSpec.describe OpenAISwarm::Util do
  # Sample messages for testing
  let(:sample_history) do
    [
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
      },
      {
        "role"=>"user",
        "content"=>"Tell me the weather in London."
      },
    ]
  end

  describe '.latest_role_user_message' do
    context 'when history is empty' do
      it 'returns empty array' do
        expect(described_class.latest_role_user_message([])).to eq([])
      end
    end

    context 'when history contains messages' do
      it 'returns the last user message' do
        result = described_class.latest_role_user_message(sample_history)
        expect(result).to eq([{
          "role" => "user",
          "content" => "Tell me the weather in London."
        }])
      end

      it 'handles history with no user messages' do
        history_without_user = [
          {
            "role" => "assistant",
            "content" => "Hello!"
          }
        ]
        expect(described_class.latest_role_user_message(history_without_user)).to eq(history_without_user)
      end

      it 'does not modify the original history' do
        original_history = sample_history.dup
        described_class.latest_role_user_message(sample_history)
        expect(sample_history).to eq(original_history)
      end
    end
  end
end
