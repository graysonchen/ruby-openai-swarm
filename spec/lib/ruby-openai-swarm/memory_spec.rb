require 'spec_helper'

RSpec.describe OpenAISwarm::Memory do
  # Test initialization and memory field normalization
  describe '#initialize' do
    context 'when initialized with memory fields' do
      let(:memory_fields) { ['name', 'age'] }
      let(:memory) { described_class.new(memory_fields: memory_fields) }

      it 'creates normalized memory fields' do
        expect(memory.instance_variable_get(:@memory_fields).size).to eq(2)
        expect(memory.instance_variable_get(:@memory_fields).first).to be_a(OpenAISwarm::Memories::Field)
      end
    end

    context 'when initialized without memory fields' do
      let(:memory) { described_class.new }

      it 'creates empty memory fields array' do
        expect(memory.instance_variable_get(:@memory_fields)).to be_empty
      end
    end
  end

  # Test core memory save functionality
  describe '#core_memory_save' do
    let(:memory) { described_class.new(memory_fields: ['name']) }
    let(:entities) { [{ 'name' => 'John Doe' }] }

    it 'delegates entity addition to entity store' do
      expect(memory.entity_store).to receive(:add_entities).with(entities)
      memory.core_memory_save(entities)
    end
  end

  # Test prompt content generation
  describe '#prompt_content' do
    context 'when memories exist' do
      let(:memory_fields) { ['name', 'age'] }
      let(:memory) { described_class.new(memory_fields: memory_fields) }
      let(:memories_data) { "John Doe, 30" }

      before do
        allow(memory).to receive(:get_memories_data).and_return(memories_data)
      end

      it 'returns formatted prompt content with memories' do
        expected_content = "You have a section of your context called [MEMORY] " \
                          "that contains the following information: name, age. " \
                          "Here are the relevant details: [MEMORY]\n" \
                          "John Doe, 30"
        expect(memory.prompt_content).to eq(expected_content)
      end
    end

    context 'when no memories exist' do
      let(:memory) { described_class.new }

      before do
        allow(memory).to receive(:get_memories_data).and_return(nil)
      end

      it 'returns nil' do
        expect(memory.prompt_content).to be_nil
      end
    end
  end

  # Test function generation
  describe '#function' do
    context 'when memory fields exist' do
      let(:memory) { described_class.new(memory_fields: ['name']) }

      it 'returns a FunctionDescriptor instance' do
        expect(memory.function).to be_a(OpenAISwarm::FunctionDescriptor)
      end

      it 'has correct target method' do
        expect(memory.function.target_method).to eq(memory.method(:core_memory_save))
      end
    end

    context 'when no memory fields exist' do
      let(:memory) { described_class.new }

      it 'returns nil' do
        expect(memory.function).to be_nil
      end
    end
  end

  # Test memories data retrieval
  describe '#get_memories_data' do
    let(:memory) { described_class.new }

    it 'delegates to entity store' do
      expect(memory.entity_store).to receive(:memories)
      memory.get_memories_data
    end
  end
end
