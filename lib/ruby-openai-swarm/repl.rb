module OpenAISwarm
  class Repl
    class << self
      def process_and_print_streaming_response(response)
        # content = ""
        content = []
        last_sender = ""
        response.each do |chunk|
          last_sender = chunk['sender'] if chunk.key?('sender')

          if chunk.key?("content") && !chunk["content"].nil?
            if content.empty? && !last_sender.empty?
              print "\033[94m content- #{last_sender}:\033[0m "
              last_sender = ""
            end
            print chunk["content"]
            content << chunk["content"]
          end

          if chunk.key?("tool_calls") && !chunk["tool_calls"].nil?
            chunk["tool_calls"].each do |tool_call|
              f = tool_call["function"]
              name = f["name"]
              next if name.nil?
              print "\033[94m tool_calls - #{last_sender}: \033[95m#{name}\033[0m()"
            end
          end

          if chunk.key?("delim") && chunk["delim"] == "end" && !content.empty?
            puts
            content = ""
          end
          return chunk["response"] if chunk.key?("response")
        end
      end

      def pretty_print_messages(messages)
        messages.each do |message|
          next unless message["role"] == "assistant"

          print "\033[94m#{message[:sender]}\033[0m: "

          puts message["content"] if message["content"]

          tool_calls = message.fetch("tool_calls", [])
          puts if tool_calls.length > 1
          tool_calls.each do |tool_call|
            func = tool_call["function"]
            name = func["name"]
            args = JSON.parse(func["arguments"] || "{}").map { |k, v| "#{k}=#{v}" }.join(", ")
            puts "\e[95m#{name}\e[0m(#{args})"
          end
        end
      end

      def run_demo_loop(starting_agent, context_variables: {}, stream: false, debug: false)
        client = OpenAISwarm.new
        puts "Starting Swarm CLI 🐝"

        messages = []
        agent = starting_agent

        loop do
          puts
          print "\033[90mUser\033[0m: "
          user_input = gets.chomp
          break if %W[exit exit! exit() quit quit()].include?(user_input.downcase)

          messages << { "role" => "user", "content" => user_input }

          if stream
            chunks = Enumerator.new do |yielder|
              client.run_and_stream(
                agent: agent,
                messages: messages,
                context_variables: context_variables,
                # stream: stream,
                debug: debug
              ) do |chunk|
                yielder << chunk
              end
            end
            response = process_and_print_streaming_response(chunks)
          else
            response = client.run(
              agent: agent,
              messages: messages,
              context_variables: context_variables,
              stream: stream,
              debug: debug
            )
            pretty_print_messages(response.messages)
          end
          messages.concat(response.messages)
          agent = response.agent
        end
      end
    end
  end
end
