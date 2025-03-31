require 'spec_helper'

RSpec.describe OpenAISwarm::Core do
  let(:client) { instance_double(OpenAI::Client) }
  let(:agent) { OpenAISwarm::Agent.new(name: "TestAgent", model: "gpt-3.5-turbo") }
  let(:messages) { [{ role: "user", content: "Hello" }] }
  let(:metadata) do
    {
      generation_name: "test-generation",
      generation_id: "gen-123",
      trace_id: "trace-123",
      trace_name: "test-trace",
      trace_metadata: { key: "value" },
      tags: ["test", "metadata"]
    }
  end

  describe '#run' do
    let(:chat_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => 'Hello! How can I help you?',
              'role' => 'assistant'
            }
          }
        ]
      }
    end

    before do
      allow(client).to receive(:chat).and_return(chat_response)
    end

    it 'passes metadata to chat completion' do
      core = described_class.new(client)
      
      expect(client).to receive(:chat) do |params|
        expect(params[:parameters][:metadata]).to eq(metadata)
        chat_response
      end

      core.run(
        agent: agent,
        messages: messages,
        metadata: metadata
      )
    end

    it 'transforms var_agent_name in metadata to actual agent name' do
      core = described_class.new(client)
      metadata_with_var = { user_id: 123, agent_name: :agent_name }
      
      expect(client).to receive(:chat) do |params|
        expect(params[:parameters][:metadata]).to eq({
          user_id: 123,
          agent_name: "TestAgent"
        })
        chat_response
      end

      core.run(
        agent: agent,
        messages: messages,
        metadata: metadata_with_var
      )
    end

    it 'works without metadata' do
      core = described_class.new(client)
      
      expect(client).to receive(:chat) do |params|
        expect(params[:parameters][:metadata]).to be_nil
        chat_response
      end

      core.run(
        agent: agent,
        messages: messages
      )
    end
  end

  describe '#run_and_stream' do
    let(:stream_response) do
      [
        { 'choices' => [{ 'delta' => { 'content' => 'Hello', 'role' => 'assistant' } }] },
        { 'choices' => [{ 'delta' => { 'content' => '!' } }] }
      ]
    end

    before do
      allow(client).to receive(:chat).and_yield(stream_response[0], 1).and_yield(stream_response[1], 1)
    end

    it 'passes metadata to streaming chat completion' do
      core = described_class.new(client)
      
      expect(client).to receive(:chat) do |params|
        expect(params[:parameters][:metadata]).to eq(metadata)
        stream_response.each { |chunk| params[:parameters][:stream].call(chunk, 1) }
      end

      core.run_and_stream(
        agent: agent,
        messages: messages,
        metadata: metadata
      ) { |_chunk| }
    end

    it 'works without metadata in streaming mode' do
      core = described_class.new(client)
      
      expect(client).to receive(:chat) do |params|
        expect(params[:parameters][:metadata]).to be_nil
        stream_response.each { |chunk| params[:parameters][:stream].call(chunk, 1) }
      end

      core.run_and_stream(
        agent: agent,
        messages: messages
      ) { |_chunk| }
    end
  end
end 