module OpenAISwarm
  module Memories
    class CoreMemoryFunction
      def self.definition(memory_fields = [])
        properties = {}

        memory_fields.each do |field|
          properties[field] = {
            type: "string",
            description: "The #{field} to remember"
          }
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
