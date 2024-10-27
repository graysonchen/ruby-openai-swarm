require_relative "../bootstrap"

client = OpenAISwarm.new

def get_weather(location:)
  "{'temp':67, 'unit':'F'}"
end

function_instance = OpenAISwarm::FunctionDescriptor.new(
  target_method: :get_weather,
  description: 'Simulate fetching weather data'
)

agent = OpenAISwarm::Agent.new(
  name: "Agent",
  instructions: "You are a helpful agent.",
  model: "gpt-4o-mini",
  functions: [function_instance]
)
# debugger logger: {:model=>"gpt-4o-mini", :messages=>[{:role=>"system", :content=>"You are a helpful agent."}, {"role"=>"user", "content"=>"What's the weather in NYC?"}], :tools=>[{:type=>"function", :function=>{:name=>"get_weather", :description=>"", :parameters=>{:type=>"object", :properties=>{:location=>{:type=>"string"}}, :required=>["location"]}}}], :stream=>false, :parallel_tool_calls=>true}
response = client.run(
  messages: [{"role" => "user", "content" => "What's the weather in NYC?"}],
  agent: agent,
  debug: true,
)

# print(response.messages[-1]["content"])
# The current temperature in New York City is 67°F. => nil
