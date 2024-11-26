require_relative "../bootstrap"

client = OpenAISwarm.new

def get_weather(location:)
  "{'temp':67, 'unit':'F'}"
end

def get_news(category:)
  [
    "Tech Company A Acquires Startup B",
    "New AI Model Revolutionizes Industry",
    "Breakthrough in Quantum Computing"
  ].sample
end

get_news_instance = OpenAISwarm::FunctionDescriptor.new(
  target_method: :get_news,
  description: 'Get the latest news headlines. The category of news, e.g., world, business, sports.'
)

get_weather_instance = OpenAISwarm::FunctionDescriptor.new(
  target_method: :get_weather,
  description: 'Simulate fetching weather data'
)

agent = OpenAISwarm::Agent.new(
  name: "Agent",
  instructions: "You are a helpful agent.",
  model: "gpt-4o-mini",
  functions: [
    get_weather_instance,
    get_news_instance
  ]
)

guide_examples = <<~GUIDE_EXAMPLES
############# GUIDE_EXAMPLES #####################################
examples:
  What's the weather in NYC?

  Tell me the weather in New York and the latest news headlines.

Details:
	1. Single Function Call
	     Example: “What’s the weather in NYC?”
	     Action: Calls get_weather with location “New York City”.
	     Response: Only provides weather details.
	2. Multiple Function Calls
	     Example: “Tell me the weather in New York and the latest news headlines.”
	     Action: Calls get_weather for weather and get_news for news.
	     Response: Combines weather and news information.

params:
  `DEBUG=1 ruby examples/basic/function_calling.rb` # turn on debug (default turn off)
################################################################
GUIDE_EXAMPLES

puts guide_examples

OpenAISwarm::Repl.run_demo_loop(agent, stream: true, debug: env_debug)
