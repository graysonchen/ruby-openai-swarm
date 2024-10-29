require_relative "../bootstrap"

def client
  OpenAISwarm.new
end

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
