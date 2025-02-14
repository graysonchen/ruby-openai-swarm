module OpenAISwarm
  class Memory
    attr_reader :memories,
                :entity_store

    def initialize(memory_fields: nil, entity_store: nil)
      @memory_fields = memory_fields
      @entity_store = Memories::EntityStore.new(entity_store)
    end

    def core_memory_save(entities)
      entity_store.add_entities(entities)
    end

    def prompt_content
      return nil if get_memories_data.nil?

      "You have a section of your context called [MEMORY] " \
      "that contains information relevant to your conversation [MEMORY]\n" \
      "#{get_memories_data}"
    end

    def function
      return nil if @memory_fields.empty?
      core_memory_save_metadata = Functions::CoreMemoryFunction.definition(@memory_fields)
      description = core_memory_save_metadata[:function][:description]
      parameters = core_memory_save_metadata[:function][:parameters]
      OpenAISwarm::FunctionDescriptor.new(
        target_method: method(:core_memory_save),
        description: description,
        parameters: parameters
      )
    end

    def get_memories_data
      entity_store&.memories
    end
  end
end
