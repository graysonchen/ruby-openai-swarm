module OpenAISwarm
  class FunctionDescriptor
    attr_reader :target_method,
                :description,
                :parameters

    def initialize(target_method:, description: '', parameters: {})
      @target_method = target_method.is_a?(Method) ? target_method : method(target_method)
      @description = description
      @parameters = parameters
    end
  end
end
