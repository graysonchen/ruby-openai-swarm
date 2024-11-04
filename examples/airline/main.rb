# https://github.com/openai/swarm/blob/main/examples/airline/main.py
require_relative "../bootstrap"
require_relative "configs/agents"
require_relative "configs/tools"
require_relative "data/prompts"
require_relative "data/routines/baggage/policies"
require_relative "data/routines/flight_modification/policies"

context_variables = {
  "customer_context" => <<~CUSTOMER_CONTEXT,
    Here is what you know about the customer's details:
    1. CUSTOMER_ID: customer_12345
    2. NAME: John Doe
    3. PHONE_NUMBER: (123) 456-7890
    4. EMAIL: johndoe@example.com
    5. STATUS: Premium
    6. ACCOUNT_STATUS: Active
    7. BALANCE: $0.00
    8. LOCATION: 1234 Main St, San Francisco, CA 94123, USA
  CUSTOMER_CONTEXT

  "flight_context" => <<~FLIGHT_CONTEXT
    The customer has an upcoming flight from LGA (Laguardia) in NYC to LAX in Los Angeles.
    The flight # is 1919. The flight departure date is 3pm ET, 5/21/2024.
  FLIGHT_CONTEXT
}

guide_examples = <<~GUIDE_EXAMPLES
############# TRIAGE_CASES #####################################
1. Conversation:
User: My bag was not delivered!
function:(transfer_to_lost_baggage) - Transferring to Lost Baggage Department...

2. Conversation:
User: I had some turbulence on my flight
function:(None) - No action required for this conversation.

3. Conversation:
User: I want to cancel my flight please
function:(transfer_to_flight_modification) Transferring to Flight Modification Department...

4. Conversation:
User: What is the meaning of life
function:(None) No action required for this conversation.
################################################################

############# FLIGHT_MODIFICATION_CASES ########################
1. Conversation:
User: I want to change my flight to one day earlier!
function:(transfer_to_flight_change)

2. Conversation:
User: I want to cancel my flight. I can't make it anymore due to a personal conflict
function:(transfer_to_flight_cancel)

3. Conversation:
User: I dont want this flight
function:(None)

params:
  `DEBUG=1 ruby examples/airline/main.rb` # turn on debug (default turn off)
################################################################


GUIDE_EXAMPLES
puts guide_examples

OpenAISwarm::Repl.run_demo_loop(triage_agent,
                                context_variables: context_variables,
                                debug: env_debug,
                                stream: true)
