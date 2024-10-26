# link: https://github.com/openai/swarm/blob/main/examples/basic/context_variables.py

# OpenAI.configure do |config|
#   config.access_token = ENV['OPENAI_ACCESS_TOKEN']
# end
OpenAI.configure do |config|
  config.access_token = ENV['OPEN_ROUTER_ACCESS_TOKEN']
  config.uri_base = "https://openrouter.ai/api/v1"
end

client = OpenAISwarm.new

def instructions(context_variables)
  name = context_variables.fetch(:name, :User)
  "You are a helpful agent. Greet the user by name (#{name})."
end

def print_account_details(context_variables = {})
  user_id = context_variables[:user_id]
  name = context_variables[:name]
  puts "Account Details: #{name} #{user_id}"
  "Success"
end

function_instance = OpenAISwarm::Transfer.new(
  transfer_agent: print_account_details,
  transfer_name: 'print_account_details'
)

agent = OpenAISwarm::Agent.new(
  name: "Agent",
  instructions: method(:instructions),
  model: "gpt-4o-mini",
  functions: [function_instance]
)

context_variables = { 'name': 'James', 'user_id': 123 }

# debugger logger: {:model=>"gpt-4o-mini", :messages=>[{:role=>"system", :content=>"You are a helpful agent. Greet the user by name (James)."}, {:role=>"user", :content=>"Hi!"}], :tools=>[{:type=>"function", :function=>{:name=>"print_account_details", :description=>"", :parameters=>{:type=>"object", :properties=>{}, :required=>[]}}}], :stream=>false, :parallel_tool_calls=>true}
response = client.run(
  messages: [{"role": "user", "content": "Hi!"}],
  agent: agent,
  context_variables: context_variables,
  debug: true,
)

# print(response.messages[-1]["content"])
# Hello, James! How can I assist you today? => nil

# debugger logger: {:model=>"gpt-4o-mini", :messages=>[{:role=>"system", :content=>"You are a helpful agent. Greet the user by name (James)."}, {:role=>"user", :content=>"Print my account details!"}], :tools=>[{:type=>"function", :function=>{:name=>"print_account_details", :description=>"", :parameters=>{:type=>"object", :properties=>{}, :required=>[]}}}], :stream=>false, :parallel_tool_calls=>true
response = client.run(
  messages: [{"role": "user", "content": "Print my account details!"}],
  agent: agent,
  context_variables: context_variables,
  debug: true,
)

# print(response.messages[-1]["content"])
# Hello, James! Your account details have been printed successfully. If you need anything else, just let me know!
