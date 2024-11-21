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
    end

    def get_chat_completion(agent, history, context_variables, model_override, stream, debug)
      context_variables = context_variables.dup
      instructions = agent.instructions.respond_to?(:call) ? agent.instructions.call(context_variables) : agent.instructions
      messages = [{ role: 'system', content: instructions }] + history
      Util.debug_print(debug, "Getting chat completion for...:", messages)

      tools = agent.functions.map { |f| Util.function_to_json(f) }
      # hide context_variables from model
      tools.each do |tool|
        params = tool[:function][:parameters]
        params[:properties].delete(CTX_VARS_NAME.to_sym)
        params[:required]&.delete(CTX_VARS_NAME.to_sym)
      end

      create_params = {
        model: model_override || agent.model,
        messages: messages,
        tools: tools.empty? ? nil : tools,
      }

      # TODO: https://platform.openai.com/docs/guides/function-calling/how-do-functions-differ-from-tools
      # create_params[:functions] = tools unless tools.empty?
      # create_params[:function_call] = agent.tool_choice if agent.tool_choice

      create_params[:tool_choice] = agent.tool_choice if agent.tool_choice
      create_params[:parallel_tool_calls] = agent.parallel_tool_calls if tools.any?

      Util.debug_print(debug, "Client chat parameters:", create_params)
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
        completion = get_chat_completion(
          active_agent,
          history,
          context_variables,
          model_override,
          stream,
          debug
        )

        message = completion.dig('choices', 0, 'message')
        Util.debug_print(debug, "Received completion:", message)

        message['sender'] = active_agent.name
        history << message

        break if !message['tool_calls'] || !execute_tools

        partial_response = handle_tool_calls(
          message['tool_calls'],
          active_agent,
          context_variables,
          debug
        )

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

    # private

    def run_and_stream(agent:, messages:, context_variables: {}, model_override: nil, debug: false, max_turns: Float::INFINITY, execute_tools: true)
      active_agent = agent
      context_variables = context_variables.dup
      history = messages.dup
      init_len = messages.length

      while history.length - init_len < max_turns && active_agent
        message = OpenAISwarm::Util.message_template(agent.name)
        completion = get_chat_completion(
          active_agent,
          history,
          context_variables,
          model_override,
          true, # stream
          debug
        )

        yield({ delim: "start" }) if block_given?
        completion.each do |chunk|
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
        history << message

        break if !message['tool_calls'] || !execute_tools

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
      end

      yield(
        'response' => Response.new(messages: history[init_len..],
                                   agent: active_agent,
                                   context_variables: context_variables)
      ) if block_given?
    end
  end
end
