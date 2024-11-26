module OpenAISwarm
  class Agent
    attr_accessor :name, :model, :instructions,
                  :functions, :tool_choice,
                  :parallel_tool_calls,
                  :resource
    # These attributes can be read and written externally. They include:
    # - name: The name of the agent.
    # - model: The model used, e.g., "gpt-4".
    # - resource: Additional custom parameters or data that the agent might need.

    def initialize(
      name: "Agent",
      model: "gpt-4",
      instructions: "You are a helpful agent.",
      functions: [],
      tool_choice: nil,
      parallel_tool_calls: true,
      resource: nil
    )
      @name = name
      @model = model
      @instructions = instructions
      @functions = functions
      @tool_choice = tool_choice
      @parallel_tool_calls = parallel_tool_calls
      @resource = resource
    end
  end
end
