require_relative "agents"

guide_examples = <<~GUIDE_EXAMPLES
############# TRIAGE_CASES #####################################

example content:
  Do I need an umbrella today? I'm in chicago.
  Tell me the weather in London.

  What is the time right now?
################################################################

GUIDE_EXAMPLES

puts guide_examples

OpenAISwarm::Repl.run_demo_loop(weather_agent, stream: true)
