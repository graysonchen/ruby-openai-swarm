require_relative "../bootstrap"

def client
  OpenAISwarm.new
end

# Client chat parameters: {:model=>"gpt-4", :messages=>[{:role=>"system", :content=>"You are a helpful agent."}, {"role"=>"user", "content"=>"Do I need an umbrella today? I'm in chicago."}, {"role"=>"assistant", "content"=>nil, "refusal"=>nil, "tool_calls"=>[{"index"=>0, "id"=>"call_spvHva4SFuDfTUk57EhuhArl", "type"=>"function", "function"=>{"name"=>"get_weather", "arguments"=>"{\n  \"location\": \"chicago\"\n}"}}], :sender=>"Weather Agent"}, {:role=>"tool", :tool_call_id=>"call_spvHva4SFuDfTUk57EhuhArl", :tool_name=>"get_weather", :content=>"{\"location\":{},\"temperature\":\"65\",\"time\":\"now\"}"}], :tools=>[{:type=>"function", :function=>{:name=>"send_email", :description=>"", :parameters=>{:type=>"object", :properties=>{:recipient=>{:type=>"string"}, :subject=>{:type=>"string"}, :body=>{:type=>"string"}}, :required=>["recipient", "subject", "body"]}}}, {:type=>"function", :function=>{:name=>"get_weather", :description=>"Get the current weather in a given location. Location MUST be a city.", :parameters=>{:type=>"object", :properties=>{:location=>{:type=>"string"}, :time=>{:type=>"string"}}, :required=>["location"]}}}], :stream=>false, :parallel_tool_calls=>true}
def get_weather(location, time= Time.now)
  { location: location, temperature: "65", time: time }.to_json
end

def send_email(recipient, subject, body)
  puts "Sending email..."
  puts "To: #{recipient}"
  puts "Subject: #{subject}"
  puts "Body: #{body}"
  puts "Sent!"
end

def function_instance_send_email
  OpenAISwarm::FunctionDescriptor.new(
    target_method: :send_email
  )
end

def function_instance_get_weather
  OpenAISwarm::FunctionDescriptor.new(
    target_method: :get_weather,
    description: 'Get the current weather in a given location. Location MUST be a city.'
  )
end

def weather_agent
  OpenAISwarm::Agent.new(
    name: "Weather Agent",
    instructions: "You are a helpful agent.",
    model: "gpt-4o-mini",
    functions: [
      function_instance_send_email,
      function_instance_get_weather
    ]
  )
end

# msg1 = "Do I need an umbrella today? I'm in chicago."
# # return: The current temperature in Chicago is 65 degrees. It doesn't look like you'll need an umbrella today!

# msg2 = "Tell me the weather in London."
# # return: The current temperature in London is 65°F.

# response = client.run(
#   messages: [{"role" => "user", "content" => msg2}],
#   agent: weather_agent,
#   debug: true,
# )
# # print(response.messages[-1]["content"])
# pp response.messages.last

# response = client.run(
#   messages: [{"role" => "user", "content" => "What is the time right now?",}],
#   agent: weather_agent,
#   debug: true,
# )
# pp response.messages.last
# # p response.messages[-1]["content"]
# # return: I'm sorry for the confusion, but as an AI, I don't have the ability to provide real-time information such as the current time. Please check the time on your device.
