def client
  OpenAISwarm.new
end

# Define functions for transferring to different agents
def transfer_to_flight_modification
  flight_modification
end

def transfer_to_flight_cancel
  flight_cancel
end

def transfer_to_flight_change
  flight_change
end

def transfer_to_lost_baggage
  lost_baggage
end

def transfer_to_triage
  OpenAISwarm::FunctionDescriptor.new(
    target_method: :triage_agent,
    description: 'Call this function when a user needs to be transferred to a different agent and a different policy.
    For instance, if a user is asking about a topic that is not handled by the current agent, call this function.'
  )
end

def triage_instructions(context_variables)
  customer_context = context_variables.fetch("customer_context", nil)
  flight_context = context_variables.fetch("flight_context", nil)

  <<~INSTRUCTIONS
    You are to triage a user's request and call a tool to transfer to the right intent.
    Once you are ready to transfer to the right intent, call the tool to transfer to the right intent.
    You don’t need to know specifics, just the topic of the request.
    When you need more information to triage the request to an agent, ask a direct question without explaining why you're asking it.
    Do not share your thought process with the user! Do not make unreasonable assumptions on behalf of the user.
    The customer context is here: #{customer_context}, and flight context is here: #{flight_context}
  INSTRUCTIONS
end

# Define agents
def triage_agent
  @triage_agent ||= OpenAISwarm::Agent.new(
    model: "gpt-4o-mini",
    name: "Triage Agent",
    instructions: method(:triage_instructions),
    functions: [method(:transfer_to_flight_modification), method(:transfer_to_lost_baggage)]
  )
end

def flight_modification
  @flight_modification ||= OpenAISwarm::Agent.new(
    model: "gpt-4o-mini",
    name: "Flight Modification Agent",
    instructions: <<~INSTRUCTIONS,
      You are a Flight Modification Agent for a customer service airlines company.
      You are an expert customer service agent deciding which sub-intent the user should be referred to.
      You already know the intent is for flight modification-related questions. First, look at the message history and see if you can determine if the user wants to cancel or change their flight.
      Ask user clarifying questions until you know whether it is a cancel request or a change flight request. Once you know, call the appropriate transfer function. Either ask clarifying questions or call one of your functions every time.
    INSTRUCTIONS
    functions: [method(:transfer_to_flight_cancel), method(:transfer_to_flight_change)],
    parallel_tool_calls: false
  )
end

def flight_cancel
  @flight_cancel ||= OpenAISwarm::Agent.new(
    model: "gpt-4o-mini",
    name: "Flight Cancel Traversal",
    instructions: STARTER_PROMPT + FLIGHT_CANCELLATION_POLICY,
    functions: [
      method(:escalate_to_agent),
      method(:initiate_refund),
      method(:initiate_flight_credits),
      method(:transfer_to_triage),
      method(:case_resolved)
    ]
  )
end

def flight_change
  @flight_change ||= OpenAISwarm::Agent.new(
    model: "gpt-4o-mini",
    name: "Flight Change Traversal",
    instructions: STARTER_PROMPT + FLIGHT_CHANGE_POLICY,
    functions: [
      method(:escalate_to_agent),
      method(:change_flight),
      method(:valid_to_change_flight),
      method(:transfer_to_triage),
      method(:case_resolved)
    ]
  )
end

def lost_baggage
  @lost_baggage ||= OpenAISwarm::Agent.new(
    model: "gpt-4o-mini",
    name: "Lost Baggage Traversal",
    instructions: STARTER_PROMPT + LOST_BAGGAGE_POLICY,
    functions: [
      method(:escalate_to_agent),
      method(:initiate_baggage_search),
      method(:transfer_to_triage),
      method(:case_resolved)
    ]
  )
end
