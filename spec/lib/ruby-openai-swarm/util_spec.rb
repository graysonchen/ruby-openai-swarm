require 'spec_helper'
require 'ruby-openai-swarm/util'

RSpec.describe OpenAISwarm::Util do
  describe '.function_to_json' do
    let(:func_instance) do
      double('FunctionInstance',
        transfer_agent: double('TransferAgent'),
        transfer_name: 'test_function',
        description: 'A test function'
      )
    end

    let(:transfer_agent) { func_instance.transfer_agent }

    before do
      allow(transfer_agent).to receive(:call).and_return(transfer_agent)
      allow(transfer_agent).to receive(:method).with('test_function').and_return(
        double('Method', parameters: [[:req, :param1], [:opt, :param2]])
      )
    end

    it 'returns a hash with the correct structure' do
      result = described_class.function_to_json(func_instance)

      expect(result).to be_a(Hash)
      expect(result[:type]).to eq('function')
      expect(result[:function]).to be_a(Hash)
      expect(result[:function][:name]).to eq('test_function')
      expect(result[:function][:description]).to eq('A test function')
      expect(result[:function][:parameters]).to be_a(Hash)
    end

    it 'correctly sets up the parameters' do
      result = described_class.function_to_json(func_instance)

      expect(result[:function][:parameters][:type]).to eq('object')
      expect(result[:function][:parameters][:properties]).to eq({
        param1: { type: 'string' },
        param2: { type: 'string' }
      })
      expect(result[:function][:parameters][:required]).to eq(['param1'])
    end
  end
end
