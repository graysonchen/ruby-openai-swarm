module OpenAISwarm
  class Memory
    attr_reader :memories,
                :entity_store

    def initialize(memory_fields: [], entity_store: nil)
      @memory_fields = normalize_memory_fields(memory_fields)
      @entity_store = Memories::EntityStore.new(entity_store)
    end

    def normalize_memory_fields(memory_fields)
      return [] if memory_fields.empty?

      memory_fields.map { |memory_field| Memories::Field.new(memory_field) }
    end

    def core_memory_save(entities)
      entity_store.add_entities(entities)
    end

    def prompt_content
      return nil if get_memories_data.nil?

      fields = @memory_fields.map(&:field).join(", ")
      "You have a section of your context called [MEMORY] " \
      "that contains the following information: #{fields}. " \
      "Here are the relevant details: [MEMORY]\n" \
      "#{get_memories_data}"
    end

    def function
      return nil if @memory_fields.empty?

      OpenAISwarm::FunctionDescriptor.new(
        target_method: method(:core_memory_save),
        description: core_memory_save_metadata[:function][:description],
        parameters: core_memory_save_metadata[:function][:parameters]
      )
    end

    def core_memory_save_metadata
      @core_memory_save_metadata ||= Memories::CoreMemoryFunction.definition(@memory_fields)
    end

    def get_memories_data
      entity_store&.memories
    end
  end
end
