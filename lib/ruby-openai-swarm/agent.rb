module OpenAISwarm
  class Agent
    attr_accessor :name, :model, :instructions,
                  :functions, :tool_choice,
                  :parallel_tool_calls,
                  :strategy,
                  :noisy_tool_calls,
                  :temperature,
                  :resource
    # These attributes can be read and written externally. They include:
    # - name: The name of the agent.
    # - model: The model used, e.g., "gpt-4".
    # - resource: Additional custom parameters or data that the agent might need.
    # - noisy_tool_calls: is an array that contains the names of tool calls that should be excluded because they are considered "noise".
    # These tool calls generate irrelevant or unnecessary messages that the agent should not send to OpenAI.
    # When filtering messages, any message that includes these tool calls will be removed from the list, preventing them from being sent to OpenAI.

    def initialize(
      name: "Agent",
      model: "gpt-4",
      instructions: "You are a helpful agent.",
      functions: [],
      tool_choice: nil,
      temperature: nil,
      parallel_tool_calls: true,
      resource: nil,
      noisy_tool_calls: [],
      strategy: {}
    )
      @name = name
      @model = model
      @instructions = instructions
      @functions = functions
      @tool_choice = tool_choice
      @temperature = temperature
      @parallel_tool_calls = parallel_tool_calls
      @resource = resource
      @noisy_tool_calls = noisy_tool_calls
      @strategy = Agents::StrategyOptions.new(strategy)
    end
  end
end
