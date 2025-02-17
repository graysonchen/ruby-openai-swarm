require 'spec_helper'

RSpec.describe OpenAISwarm::Memories::Field do
  let(:field_name) { :test_field }
  let(:field_value) { "test value" }
  let(:field) { described_class.new(field_name, field_value) }

  describe '#initialize' do
    it 'creates a field with name and value' do
      expect(field.name).to eq(field_name)
      expect(field.value).to eq(field_value)
    end

    it 'accepts different types of values' do
      number_field = described_class.new(:number, 42)
      expect(number_field.value).to eq(42)

      array_field = described_class.new(:array, [1, 2, 3])
      expect(array_field.value).to eq([1, 2, 3])

      hash_field = described_class.new(:hash, { key: 'value' })
      expect(hash_field.value).to eq({ key: 'value' })
    end
  end

  describe '#to_h' do
    it 'returns a hash representation of the field' do
      expect(field.to_h).to eq({
        name: field_name,
        value: field_value
      })
    end
  end

  describe '#==' do
    it 'returns true when comparing identical fields' do
      field2 = described_class.new(field_name, field_value)
      expect(field).to eq(field2)
    end

    it 'returns false when comparing fields with different names' do
      field2 = described_class.new(:other_field, field_value)
      expect(field).not_to eq(field2)
    end

    it 'returns false when comparing fields with different values' do
      field2 = described_class.new(field_name, "other value")
      expect(field).not_to eq(field2)
    end
  end

  describe '#clone' do
    it 'creates a deep copy of the field' do
      cloned_field = field.clone
      expect(cloned_field).to eq(field)
      expect(cloned_field.object_id).not_to eq(field.object_id)
    end

    it 'creates independent copies of complex values' do
      array_field = described_class.new(:array, [1, 2, 3])
      cloned_field = array_field.clone
      cloned_field.value << 4
      expect(array_field.value).to eq([1, 2, 3])
      expect(cloned_field.value).to eq([1, 2, 3, 4])
    end
  end

  describe 'validation' do
    it 'raises error when name is nil' do
      expect {
        described_class.new(nil, "value")
      }.to raise_error(ArgumentError, "Field name cannot be nil")
    end

    it 'raises error when name is empty' do
      expect {
        described_class.new("", "value")
      }.to raise_error(ArgumentError, "Field name cannot be empty")
    end
  end

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