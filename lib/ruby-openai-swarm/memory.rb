module OpenAISwarm
  class Memory
    attr_reader :memories

    def initialize(memory_fields: nil)
      @memories = {}
      @memory_fields = memory_fields
    end

    def core_memory_save(args)
      puts "core_memory_save"
      args.each { |key, value| add(key, value) }
    #   @memories[section].merge!(memory)
    end

    def prompt_content
      return nil if memories.empty?

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

    def add(section, memory)
      @memories[section] = memory
    end

    def get(section)
      @memories[section]
    end

    def clear(section = nil)
      @memories = {}
    end

    def get_memories_data
      memories.to_json
    end
  end
end
