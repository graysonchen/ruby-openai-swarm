module OpenAISwarm
  class Agent
    attr_accessor :name, :model, :instructions, :functions, :tool_choice, :parallel_tool_calls

    def initialize(
      name: "Agent",
      model: "gpt-4",
      instructions: "You are a helpful agent.",
      functions: [],
      tool_choice: nil,
      parallel_tool_calls: true
    )
      @name = name
      @model = model
      @instructions = instructions
      @functions = functions
      @tool_choice = tool_choice
      @parallel_tool_calls = parallel_tool_calls
    end
  end
end
