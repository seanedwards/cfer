require_relative '../core/client'
module Cfer::Cfn

  class Client < Cfer::Core::Client
    attr_reader :name
    attr_reader :stack_cache

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

    def resolve(param)
      Cfer::Cfn::ParameterValue.new(param).evaluate(self)
    end

    def flush_cache
      @stack_cache = {}
    end

    def converge(stack, options = {})

      Preconditions.check(@name).is_not_nil
      Preconditions.check(stack) { is_not_nil and has_type(Cfer::Core::Stack) }

      response = validate_template(template_body: stack.to_cfn)
      parameters = response.parameters.map do |tmpl_param|
        input_param = ParameterValidator.new(stack.parameters)[tmpl_param.parameter_key]
        cfn_param = input_param || (Cfer::Cfn::ParameterValue.new(tmpl_param.default_value) if tmpl_param.default_value)

        p = if cfn_param
          {
            parameter_key: tmpl_param.parameter_key,
            parameter_value: cfn_param.evaluate(self),
            use_previous_value: false
          }
        else
          {
            parameter_key: tmpl_param.parameter_key,
            use_previous_value: true
          }
        end

        output_val = tmpl_param.no_echo ? '*****' : p[:parameter_value]
        Cfer::LOGGER.info "Parameter #{p[:parameter_key]}=#{output_val}"
        p
      end

      options = {
        stack_name: name,
        template_body: stack.to_cfn,
        parameters: parameters,
        capabilities: response.capabilities
      }

      created = false
      cfn_stack = begin
          created = true
          create_stack options
        rescue Cfer::Util::StackExistsError
          update_stack options
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

    def fetch_cfn!
    end

    def to_h
      @stack.to_h
    end

    private

    def for_each_event(stack_name)
      describe_stack_events(stack_name: stack_name).stack_events.each do |event|
        yield event
      end
    end
  end
end

