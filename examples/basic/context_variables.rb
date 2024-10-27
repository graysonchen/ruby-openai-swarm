require_relative "../bootstrap"
# link: https://github.com/openai/swarm/blob/main/examples/basic/context_variables.py

client = OpenAISwarm.new

def instructions(context_variables)
  name = context_variables.fetch(:name, :User)
  "You are a helpful agent. Greet the user by name (#{name})."
end

def print_account_details(context_variables: {})
  puts "print_account_details context_variables: #{context_variables.inspect}"

  user_id = context_variables[:user_id]
  name = context_variables[:name]
  puts "Account Details: name: #{name}, user_id: #{user_id}"
  "Success"
end

function_instance = OpenAISwarm::FunctionDescriptor.new(
  target_method: :print_account_details,
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
msg = response.messages.last
# Hello, James! How can I assist you today?

msg['content'].include?('James')

# debugger logger: {:model=>"gpt-4o-mini", :messages=>[{:role=>"system", :content=>"You are a helpful agent. Greet the user by name (James)."}, {:role=>"user", :content=>"Print my account details!"}], :tools=>[{:type=>"function", :function=>{:name=>"print_account_details", :description=>"", :parameters=>{:type=>"object", :properties=>{}, :required=>[]}}}], :stream=>false, :parallel_tool_calls=>true
response = client.run(
  messages: [{"role": "user", "content": "Print my account details!"}],
  agent: agent,
  context_variables: context_variables,
  debug: true,
)
msg = response.messages.last
msg['content']
response.context_variables == {:name=>"James", :user_id=>123}

# print(response.messages[-1]["content"])
# Hello, James! Your account details have been printed successfully. If you need anything else, just let me know!
#
# print_account_details context_variables: {:name=>"James", :user_id=>123}
# Account Details: name: James, user_id: 123
