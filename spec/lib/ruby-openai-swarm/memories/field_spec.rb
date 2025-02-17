require 'spec_helper'

RSpec.describe OpenAISwarm::Memories::Field do
  # Test initialization with a string
  describe '#initialize with string' do
    it 'sets the field value when initialized with a string' do
      field = described_class.new('test_field')
      expect(field.field).to eq('test_field')
      expect(field.tool_call_description).to be_nil
    end
  end

  # Test initialization with a valid hash
  describe '#initialize with hash' do
    it 'sets both field and tool_call_description when initialized with a valid hash' do
      field = described_class.new(
        field: 'test_field',
        tool_call_description: 'test description'
      )
      expect(field.field).to eq('test_field')
      expect(field.tool_call_description).to eq('test description')
    end

    it 'sets only field when tool_call_description is not provided' do
      field = described_class.new(field: 'test_field')
      expect(field.field).to eq('test_field')
      expect(field.tool_call_description).to be_nil
    end
  end

  # Test validation errors
  describe 'validation' do
    it 'raises ArgumentError when :field is missing from hash' do
      expect {
        described_class.new(tool_call_description: 'test description')
      }.to raise_error(ArgumentError, 'memory_field must include :field')
    end

    it 'raises ArgumentError when invalid keys are present' do
      expect {
        described_class.new(
          field: 'test_field',
          invalid_key: 'value'
        )
      }.to raise_error(
        ArgumentError,
        'Invalid memory fields: invalid_key. Valid fields are: field, tool_call_description'
      )
    end
  end

  # Test parse_hash method
  describe '#parse_hash' do
    it 'correctly parses a valid hash' do
      # Initialize with valid field to avoid validation error
      field = described_class.new(field: 'initial')

      field.send(:parse_hash, {
        field: 'test_field',
        tool_call_description: 'test description'
      })

      expect(field.field).to eq('test_field')
      expect(field.tool_call_description).to eq('test description')
    end
  end

  # Test parse_string method
  describe '#parse_string' do
    it 'correctly parses a string' do
      field = described_class.new(field: 'initial')  # Initialize with valid field
      field.send(:parse_string, 'test_field')
      expect(field.field).to eq('test_field')
    end
  end
end
