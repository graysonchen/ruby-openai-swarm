module OpenAISwarm
  module Memories
    class Field
      attr_accessor :field,
                    :tool_call_description

      VALID_MEMORY_FIELDS = [:field, :tool_call_description].freeze

      def initialize(memory_field)
        memory_field.is_a?(Hash) ? parse_hash(memory_field) : parse_string(memory_field)
      end

      def parse_hash(memory_field)
        validate_memory_field!(memory_field)

        @field = memory_field[:field]
        @tool_call_description = memory_field[:tool_call_description]
      end

      def parse_string(memory_field)
        @field = memory_field
      end

      private

      def validate_memory_field!(memory_field)
        unless memory_field.include?(:field)
          raise ArgumentError, "memory_field must include :field"
        end

        invalid_fields = memory_field.keys - VALID_MEMORY_FIELDS

        unless invalid_fields.empty?
          raise ArgumentError, "Invalid memory fields: #{invalid_fields.join(', ')}. Valid fields are: #{VALID_MEMORY_FIELDS.join(', ')}"
        end
      end
    end
  end
end
