require 'spec_helper'

RSpec.describe OpenAISwarm::Memories::CoreMemoryFunction do
  describe '.definition' do
    # Test with empty memory fields
    context 'when no memory fields are provided' do
      it 'returns a function definition with empty properties' do
        result = described_class.definition([])
        
        expect(result).to be_a(Hash)
        expect(result[:type]).to eq('function')
        expect(result[:function][:name]).to eq('core_memory_save')
        expect(result[:function][:parameters][:properties]).to be_empty
      end
    end

    # Test with memory fields
    context 'when memory fields are provided' do
      let(:memory_field) do
        field = OpenAISwarm::Memories::Field.new('name')
        field.tool_call_description = ' This is used to store the name.'
        field
      end

      let(:memory_fields) { [memory_field] }

      it 'returns a function definition with correct properties' do
        result = described_class.definition(memory_fields)
        
        expect(result).to be_a(Hash)
        expect(result[:type]).to eq('function')
        expect(result[:function]).to include(
          name: 'core_memory_save',
          description: 'Save important information about you, the agent or the human you are chatting with.'
        )

        # Check properties structure
        properties = result[:function][:parameters][:properties]
        expect(properties).to include('name')
        expect(properties['name']).to include(
          type: 'string',
          description: 'The name to remember. This is used to store the name.'
        )
      end
    end

    # Test with multiple memory fields
    context 'when multiple memory fields are provided' do
      let(:memory_fields) do
        [
          OpenAISwarm::Memories::Field.new('name'),
          OpenAISwarm::Memories::Field.new('age')
        ]
      end

      it 'includes all fields in the properties' do
        result = described_class.definition(memory_fields)
        properties = result[:function][:parameters][:properties]
        
        expect(properties.keys).to contain_exactly('name', 'age')
        expect(properties['name'][:type]).to eq('string')
        expect(properties['age'][:type]).to eq('string')
      end
    end
  end
end 