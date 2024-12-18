require 'ruby/openai'
begin
  require 'pry'
rescue LoadError
end

module OpenAISwarm
  class Core
    include Util
    CTX_VARS_NAME = 'context_variables'

    def initialize(client = nil)
      @client = client || OpenAI::Client.new
      @logger = OpenAISwarm::Logger.instance.logger
    end

    def get_chat_completion(agent_tracker, history, context_variables, model_override, stream, debug)
      agent = agent_tracker.current_agent
      context_variables = context_variables.dup
      instructions = agent.instructions.respond_to?(:call) ? agent.instructions.call(context_variables) : agent.instructions
      messages = [{ role: 'system', content: instructions }] + history

      # Util.debug_print(debug, "Getting chat completion for...:", messages)

      tools = agent.functions.map { |f| Util.function_to_json(f) }
      # hide context_variables from model
      tools.each do |tool|
        params = tool[:function][:parameters]
        params[:properties].delete(CTX_VARS_NAME.to_sym)
        params[:required]&.delete(CTX_VARS_NAME.to_sym)
      end

      cleaned_messages = OpenAISwarm::Util.clean_message_tools(messages, agent.noisy_tool_calls)

      create_params = {
        model: model_override || agent.model,
        messages: cleaned_messages,
        tools: tools.empty? ? nil : tools,
      }

      # TODO: https://platform.openai.com/docs/guides/function-calling/how-do-functions-differ-from-tools
      # create_params[:functions] = tools unless tools.empty?
      # create_params[:function_call] = agent.tool_choice if agent.tool_choice

      create_params[:temperature] = agent.temperature if agent.temperature
      create_params[:tool_choice] = agent.tool_choice if agent.tool_choice
      create_params[:parallel_tool_calls] = agent.parallel_tool_calls if tools.any?

      Util.debug_print(debug, "Getting chat completion for...:", create_params)
      log_message(:info, "Getting chat completion for...:", create_params)
      log_message(:info, " create_params[:tools]:", create_params[:tools])

      puts "tracking_agents_tool_name:  #{agent_tracker.tracking_agents_tool_name}"

      if stream
        return Enumerator.new do |yielder|
          @client.chat(parameters: create_params.merge(
            stream: proc do |chunk, _bytesize|
              yielder << chunk
            end
          ))
        end
      else
        response = @client.chat(parameters: create_params)
      end

      Util.debug_print(debug, "API Response:", response)
      response
    rescue OpenAI::Error => e
      log_message(:error, "OpenAI API Error: #{e.message}")
      Util.debug_print(true, "OpenAI API Error:", e.message)
      raise
    end

    def handle_function_result(result, debug)
      case result
      when Result
        result
      when Agent
        Result.new(
          value: JSON.generate({ assistant: result.name }),
          agent: result
        )
      else
        begin
          Result.new(value: result.to_s)
        rescue => e
          error_message = "Failed to cast response to string: #{result}. Make sure agent functions return a string or Result object. Error: #{e}"
          Util.debug_print(debug, error_message)
          raise TypeError, error_message
        end
      end
    end

    def handle_tool_calls(tool_calls, active_agent, context_variables, debug)
      functions = active_agent.functions

      function_map = functions.map do |f|
        if f.is_a?(OpenAISwarm::FunctionDescriptor)
          [f.target_method.name, f.target_method]
        else
          [f.name, f]
        end
      end.to_h.transform_keys(&:to_s)

      partial_response = Response.new(
        messages: [],
        agent: nil,
        context_variables: {}
      )

      tool_calls.each do |tool_call|
        name = tool_call.dig('function', 'name')
        unless function_map.key?(name)
          Util.debug_print(debug, "Tool #{name} not found in function map.")
          log_message(:error, "Tool #{name} not found in function map.")
          partial_response.messages << {
            'role' => 'tool',
            'tool_call_id' => tool_call['id'],
            'tool_name' => name,
            'content' => "Error: Tool #{name} not found."
          }
          next
        end

        args = JSON.parse(tool_call.dig('function', 'arguments') || '{}')
        Util.debug_print(debug, "Processing tool call: #{name} with arguments #{args}")
        log_message(:info, "Processing tool call: #{name} with arguments #{args}")

        func = function_map[name]
        # pass context_variables to agent functions
        args[CTX_VARS_NAME] = context_variables if func.parameters.map(&:last).include?(CTX_VARS_NAME.to_sym)
        is_parameters = func.parameters.any?
        arguments = args.transform_keys(&:to_sym)

        raw_result = is_parameters ? func.call(**arguments) : func.call
        result = handle_function_result(raw_result, debug)

        partial_response.messages << {
          'role' => 'tool',
          'tool_call_id' => tool_call['id'],
          'tool_name' => name,
          'content' => result.value
        }

        partial_response.context_variables.merge!(result.context_variables)
        partial_response.agent = result.agent if result.agent
      end

      partial_response
    end

    def run(agent:, messages:, context_variables: {}, model_override: nil, stream: false, debug: false, max_turns: Float::INFINITY, execute_tools: true)
      agent_tracker = OpenAISwarm::Agents::ChangeTracker.new(agent)
      if stream
        return run_and_stream(
          agent: agent,
          messages: messages,
          context_variables: context_variables,
          model_override: model_override,
          debug: debug,
          max_turns: max_turns,
          execute_tools: execute_tools
        )
      end

      active_agent = agent
      context_variables = context_variables.dup
      history = messages.dup
      init_len = messages.length

      while history.length - init_len < max_turns && active_agent
        agent_tracker.update(active_agent)
        history = OpenAISwarm::Util.latest_role_user_message(history) if agent_tracker.switch_agent_reset_message?

        completion = get_chat_completion(
          agent_tracker,
          history,
          context_variables,
          model_override,
          stream,
          debug
        )

        message = completion.dig('choices', 0, 'message')
        Util.debug_print(debug, "Received completion:", message)
        log_message(:info, "Received completion:", message)

        message['sender'] = active_agent.name
        history << message

        if !message['tool_calls'] || !execute_tools
          log_message(:info, "Ending turn.")
          break
        end

        partial_response = handle_tool_calls(
          message['tool_calls'],
          active_agent,
          context_variables,
          debug
        )

        if partial_response.agent
          agent_tool_name = message['tool_calls'].dig(0, 'function', 'name')
          agent_tracker.add_tracking_agents_tool_name(agent_tool_name)

          # agent_tracker.push_agent_tool_call_name
          # debugger
          puts "1 agent >>>>>>>>>>> message['tool_calls']: #{message['tool_calls']}"
          puts "1 agent >>>>>>>>>>> partial_response.agent: #{partial_response&.agent&.name}"
        else
          puts "2>>>>>>>>>>> message['tool_calls']: #{message['tool_calls']}"
          puts "2>>>>>>>>>>> partial_response.agent: #{partial_response&.agent&.name}"
        end

        history.concat(partial_response.messages)
        context_variables.merge!(partial_response.context_variables)
        active_agent = partial_response.agent if partial_response.agent
      end

      Response.new(
        messages: history[init_len..],
        agent: active_agent,
        context_variables: context_variables
      )
    end

    # TODO(Grayson): a lot of copied code here that will be refactored
    def run_and_stream(agent:, messages:, context_variables: {}, model_override: nil, debug: false, max_turns: Float::INFINITY, execute_tools: true)
      agent_tracker = OpenAISwarm::Agents::ChangeTracker.new(agent)
      active_agent = agent
      context_variables = context_variables.dup
      history = messages.dup
      init_len = messages.length

      while history.length - init_len < max_turns && active_agent
        agent_tracker.update(active_agent)
        history = OpenAISwarm::Util.latest_role_user_message(history) if agent_tracker.switch_agent_reset_message?

        message = OpenAISwarm::Util.message_template(agent.name)
        completion = get_chat_completion(
          agent_tracker,
          history,
          context_variables,
          model_override,
          true, # stream
          debug
        )

        yield({ delim: "start" }) if block_given?
        completion.each do |chunk|
          if chunk['error']
            details = {
              'response' =>
                 Response.new(
                   messages: messages,
                   agent: active_agent,
                   context_variables: context_variables)
            }
            raise OpenAISwarm::Error.new(chunk['error'], details)
          end

          delta = chunk.dig('choices', 0, 'delta')
          if delta['role'] == "assistant"
            delta['sender'] = active_agent.name
          end

          yield delta if block_given?

          delta.delete('role')
          delta.delete('sender')
          Util.merge_chunk(message, delta)
        end
        yield({ delim: "end" }) if block_given?

        message['tool_calls'] = message['tool_calls'].values
        message['tool_calls'] = nil if message['tool_calls'].empty?
        Util.debug_print(debug, "Received completion:", message)
        log_message(:info, "Received completion:", message)

        history << message


        if !message['tool_calls'] || !execute_tools
          log_message(:info, "Ending turn.")
          break
        end

        # convert tool_calls to objects
        tool_calls = message['tool_calls'].map do |tool_call|
          OpenStruct.new(
            id: tool_call['id'],
            function: OpenStruct.new(
              arguments: tool_call['function']['arguments'],
              name: tool_call['function']['name']
            ),
            type: tool_call['type']
          )
        end

        partial_response = handle_tool_calls(
          tool_calls,
          active_agent,
          context_variables,
          debug
        )

        history.concat(partial_response.messages)
        context_variables.merge!(partial_response.context_variables)
        active_agent = partial_response.agent if partial_response.agent

        tool_call_messages = (Array.wrap(message) + partial_response.messages)
        yield(
          'tool_call_messages' => Response.new(
            messages: tool_call_messages,
            agent: active_agent,
            context_variables: context_variables)
        ) if block_given?
      end

      yield(
        'response' => Response.new(messages: history[init_len..],
                                   agent: active_agent,
                                   context_variables: context_variables)
      ) if block_given?
    end

    private

    def log_message(level, message, data = nil)
      return unless @logger

      log_text = message
      log_text += "\n#{data.inspect}" if data

      @logger.send(level, log_text)
    end
  end
end
