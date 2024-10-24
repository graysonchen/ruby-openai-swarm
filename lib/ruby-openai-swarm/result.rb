module OpenAISwarm
  class Result
    attr_accessor :value, :agent, :context_variables

    def initialize(value: "", agent: nil, context_variables: {})
      @value = value
      @agent = agent
      @context_variables = context_variables
    end
  end
end
