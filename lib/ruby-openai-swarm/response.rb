module OpenAISwarm
  class Response
    attr_accessor :messages, :agent, :context_variables

    def initialize(messages: [], agent: nil, context_variables: {})
      @messages = messages
      @agent = agent
      @context_variables = context_variables
    end
  end
end
