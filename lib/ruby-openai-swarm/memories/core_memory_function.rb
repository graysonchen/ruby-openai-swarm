module OpenAISwarm
  module Memories
    class CoreMemoryFunction
      def self.definition(memory_fields = [])
        properties = {}

        memory_fields.each do |memory_field|
          field = memory_field.field
          description = "The #{field} to remember." + memory_field&.tool_call_description.to_s
          properties[field] = { type: "string", description: description }
        end

        {
          type: "function",
          function: {
            name: "core_memory_save",
            description: "Save important information about you, the agent or the human you are chatting with.",
            parameters: {
              type: "object",
              properties: properties,
            }
          }
        }
      end
    end
  end
end
