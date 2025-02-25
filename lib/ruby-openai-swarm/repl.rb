module OpenAISwarm
  class Repl
    class << self
      def process_and_print_streaming_response(response)
        content = []
        last_sender = ""
        response.each do |stream|
          delta = stream['delta']
          if delta
            last_sender = delta['sender'] if delta.key?('sender')

            if delta.key?("content") && !delta["content"].nil?
              if content.empty? && !last_sender.empty?
                puts
                print "\033[94m#{last_sender}:\033[0m "
                last_sender = ""
              end
              print delta["content"]
              content << delta["content"]
            end
          end

          if stream.key?("tool_calls") && !stream["tool_calls"].nil?
            stream["tool_calls"].each do |tool_call|
              f = tool_call["function"]
              name = f["name"]
              next if name.nil?
              print "\033[94m#{last_sender}: \033[95m#{name}\033[0m()"
            end
          end

          if stream.key?("delim") && stream["delim"] == "end" && !content.empty?
            puts
            content = ""
          end
          return stream["response"] if stream.key?("response")
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
