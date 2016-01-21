require_relative '../core/client'
module Cfer::Cfn

  class Client < Cfer::Core::Client
    attr_reader :name
    attr_reader :stack

    def initialize(options)
      @name = options[:stack_name]
      options.delete :stack_name
      @cfn = Aws::CloudFormation::Client.new(options)
      flush_cache
    end

    def create_stack(*args)
      begin
        @cfn.create_stack(*args)
      rescue Aws::CloudFormation::Errors::AlreadyExistsException
        raise Cfer::Util::StackExistsError
      end
    end

    def responds_to?(method)
      @cfn.responds_to? method
    end

    def method_missing(method, *args, &block)
      @cfn.send(method, *args, &block)
    end

    def converge(stack, options = {})
      Preconditions.check(@name).is_not_nil
      Preconditions.check(stack) { is_not_nil and has_type(Cfer::Core::Stack) }

      @stack = fetch_stack(@name)

      response = validate_template(template_body: stack.to_cfn)

      parameters = response.parameters.map do |tmpl_param|
        cfn_param = stack.parameters[tmpl_param.parameter_key] ||
         stack[:Parameters][tmpl_param.parameter_key][:Default]

        output_val = tmpl_param.no_echo ? '*****' : cfn_param
        Cfer::LOGGER.debug "Parameter #{tmpl_param.parameter_key}=#{output_val}"

        if cfn_param
          {
            parameter_key: tmpl_param.parameter_key,
            parameter_value: cfn_param,
            use_previous_value: false
          }
        else
          {
            parameter_key: tmpl_param.parameter_key,
            use_previous_value: true
          }
        end
      end

      created = false
      cfn_stack =
        begin
          create_stack stack_name: name,
            template_body: stack.to_cfn,
            parameters: parameters,
            capabilities: response.capabilities
          created = true
        rescue Cfer::Util::StackExistsError
          update_stack stack_name: name,
            template_body: stack.to_cfn,
            parameters: parameters,
            capabilities: response.capabilities
        end

      flush_cache
      cfn_stack
    end

    # Yields to the given block for each CloudFormation event that qualifies, given the specified options.
    # @param options [Hash] The options hash
    # @option options [Fixnum] :number The maximum number of already-existing CloudFormation events to yield.
    # @option options [Boolean] :follow Set to true to wait until the stack enters a `COMPLETE` or `FAILED` state, yielding events as they occur.
    def tail(options = {}, &block)
      q = []
      event_id_highwater = nil
      counter = 0
      number = options[:number] || 0
      for_each_event name do |event|
        q.unshift event if counter < number
        counter = counter + 1
      end

      while q.size > 0
        event = q.shift
        yield event
        event_id_highwater = event.event_id
      end

      running = true
      if options[:follow]
        while running
          stack_status = describe_stacks(stack_name: name).stacks.first.stack_status
          running = running && (/.+_(COMPLETE|FAILED)$/.match(stack_status) == nil)

          yielding = true
          for_each_event name do |event|
            if event_id_highwater == event.event_id
              yielding = false
            end

            if yielding
              q.unshift event
            end
          end

          while q.size > 0
            event = q.shift
            yield event
            event_id_highwater = event.event_id
          end

          sleep 1 if running unless options[:no_sleep]
        end
      end
    end

    def fetch_stack(stack_name = @name)
      @stack_cache[stack_name] ||= describe_stacks(stack_name: stack_name).stacks.first.to_h
    end

    def fetch_output(stack_name, output_name)
      stack = fetch_stack(stack_name)

      output = stack[:outputs].find do |o|
        o[:output_key] == output_name
      end

      if output
        output[:output_value]
      else
        raise CferError, "Stack #{stack_name} has no output value named `#{output_name}`"
      end
    end

    def to_h
      @stack.to_h
    end

    private

    def flush_cache
      @stack_cache = {}
    end

    def for_each_event(stack_name)
      describe_stack_events(stack_name: stack_name).stack_events.each do |event|
        yield event
      end
    end
  end
end

