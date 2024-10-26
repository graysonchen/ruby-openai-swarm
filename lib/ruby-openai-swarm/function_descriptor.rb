module OpenAISwarm
  class FunctionDescriptor
    attr_reader :target_method, :description

    def initialize(target_method:, description: '')
      @target_method = target_method.is_a?(Method) ? target_method : method(target_method)
      @description = description
    end
  end
end
