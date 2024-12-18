require 'spec_helper'

RSpec.describe OpenAISwarm::AgentChangeTracker do
  let(:agent1) { OpenAISwarm::Agent.new(name: "agent1") }
  let(:agent2) { OpenAISwarm::Agent.new(name: "agent2") }

  describe '#initialize' do
    it 'sets the current agent and nil as previous agent' do
      tracker = described_class.new(agent1)

      expect(tracker.current_agent).to eq(agent1)
      expect(tracker.previous_agent).to be_nil
    end
  end

  describe '#update' do
    it 'updates current agent and moves old current to previous' do
      tracker = described_class.new(agent1)
      tracker.update(agent2)

      expect(tracker.current_agent).to eq(agent2)
      expect(tracker.previous_agent).to eq(agent1)
    end
  end

  describe '#agent_changed?' do
    let(:tracker) { described_class.new(agent1) }

    context 'when agent has changed' do
      it 'returns true' do
        tracker.update(agent2)
        expect(tracker.agent_changed?).to be true
      end
    end

    context 'when agent has not changed' do
      it 'returns false' do
        tracker.update(agent1)
        expect(tracker.agent_changed?).to be false
      end
    end

    context 'when only first agent is set' do
      it 'returns true' do
        expect(tracker.agent_changed?).to be true
      end
    end
  end
end
