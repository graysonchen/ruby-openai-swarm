module OpenAISwarm
  module Functions
    class CoreMemoryFunction
      def self.definition(memory_fields = [])
        properties = {
          section: {
            type: "string",
            enum: ["human", "agent"],
            description: "Must be either 'human' (to save information about the human) or 'agent'(to save information about yourself)"
          }
        }

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
            #   required: ["section"] + memory_fields
            }
          }
        }
      end

      def initialize(agent, memory_fields = [])
        @agent = agent
        @memory_fields = memory_fields
      end

      def call(section:, **memories)
        memory_data = memories.transform_keys(&:to_s)
        @agent.memory.add(section, memory_data)
        "Memory saved in #{section} section: #{memory_data}"
      end
    end
  end
end 