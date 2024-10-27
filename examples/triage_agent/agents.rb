require "bundler/setup"
require "ruby-openai-swarm"

OpenAI.configure do |config|
  config.access_token = ENV['OPEN_ROUTER_ACCESS_TOKEN']
  config.uri_base = "https://openrouter.ai/api/v1"
end

client = OpenAISwarm.new

def process_refund(item_id, reason = "NOT SPECIFIED")
  # Refund an item. Make sure you have the item_id of the form item_...
  # Ask for user confirmation before processing the refund.
  puts "[mock] Refunding item #{item_id} because #{reason}..."
  "Success!"
end

def process_refund_function_instance
  OpenAISwarm::FunctionDescriptor.new(
    target_method: :process_refund,
    description: "Refund an item. Make sure you have the item_id of the form item_...Ask for user confirmation before processing the refund."
  )
end

def apply_discount
  # Apply a discount to the user's cart.
  puts "[mock] Applying discount..."
  "Applied discount of 11%"
end

def apply_discount_function_instance
  OpenAISwarm::FunctionDescriptor.new(
    target_method: :apply_discount,
    description: "Apply a discount to the user's cart."
  )
end

def triage_agent
  @triage_agent ||=
    OpenAISwarm::Agent.new(
      name: "Triage Agent",
      instructions: "Determine which agent is best suited to handle the user's request, and transfer the conversation to that agent."
    )
end

def sales_agent
  @sales_agent ||=
    OpenAISwarm::Agent.new(
      name: "Sales Agent",
      instructions: "Be super enthusiastic about selling bees."
    )
end

def refunds_agent
  @refunds_agent ||=
    OpenAISwarm::Agent.new(
      name: "Refunds Agent",
      instructions: "Help the user with a refund. If the reason is that it was too expensive, offer the user a refund code. If they insist, then process the refund.",
      functions: [
        process_refund_function_instance,
        apply_discount_function_instance
      ]
    )
end

transfer_back_to_triage = OpenAISwarm::FunctionDescriptor.new(
  target_method: :triage_agent,
  description: "Call this function if a user is asking about a topic that is not handled by the current agent."
)

def transfer_to_sales
  sales_agent
end

def transfer_to_refunds
  refunds_agent
end

# Assign functions to agents
triage_agent.functions = [method(:transfer_to_sales), method(:transfer_to_refunds)]
sales_agent.functions << transfer_back_to_triage
refunds_agent.functions << transfer_back_to_triage

user_input = 'I want to make a refund!'
messages = [{ "role": "user", "content": user_input }]

response = client.run(agent: triage_agent, messages: messages, debug: true)

p response.messages.last["content"]
# binding.pry
