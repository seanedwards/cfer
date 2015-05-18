module Cfer::Cfn
  class Stack < Cfer::Block
    include Cfer::Cfn

    attr_reader :parameters

    def initialize(parameters = {})
      @parameters = parameters
    end

    def version(v)
      self[:AwsTemplateFormatVersion] = v
    end

    def description(desc)
      self[:Description] = desc
    end

    def parameter(name, options = {}, d=nil)
      self[:Parameters] ||= {}

      options[:type] ||= 'String'
      param = {}
      options.each do |k, v|
        param[k.to_s.camelize] = v
      end
      self[:Parameters][name] = param
    end

    def resource(name, type, options = {}, &block)
      self[:Resources] ||= {}

      clazz = "CferExt::#{type}".split('::').inject(Object) { |o, c| o.const_get c if o && o.const_defined?(c) } || Cfer::Cfn::Resource
      rc = clazz.new(type, options, &block)

      self[:Resources][name] = rc
    end

    def output(name, value)
      self[:Outputs] ||= {}

      self[:Outputs][name] = {'Value' => value}
    end
  end

  class CfnStack
    attr_reader :stack
    attr_reader :name
    def initialize(name, stack = nil)
      @stack = stack
      @name = name
    end

    def converge(options)
      @cfn ||= Aws::CloudFormation::Client.new

      response = @cfn.validate_template(template_body: to_cfn)
      parameters = response.parameters.map do |param|
        if options[:parameters][param.parameter_key]
          {
            ParameterKey: param.parameter_key,
            ParameterValue: options[:parameters][param.parameter_key],
            UsePreviousValue: false
          }
        else
          {
            ParameterKey: param.parameter_key,
            UsePreviousValue: true
          }
        end
      end

      options = {
        stack_name: name,
        template_body: to_cfn,
        parameters: parameters,
        capabilities: response.capabilities
      }

      created = false
      cfn_stack = begin
          created = true
          @cfn.create_stack options.merge(on_failure: options[:on_failure])
        rescue Aws::CloudFormation::Errors::AlreadyExistsException
          @cfn.update_stack options
        end

      cfn_stack
    end

    def tail(options = {})
      @cfn ||= Aws::CloudFormation::Client.new

      q = []
      event_id_highwater = nil
      counter = 0
      for_each_event(name) do |event|
        q.unshift event if counter < options[:number]
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
          yielding = true
          for_each_event(name) do |event|
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

            running = false if event.resource_type == 'AWS::CloudFormation::Stack' && options[:done_states].contains?(event.resource_status)
            event_id_highwater = event.event_id
          end

          sleep 1
        end
      end
    end

    def to_h
      @stack.to_h
    end

    def to_cfn
      to_h.to_json
    end

    private
    def for_each_event(stack_name)
      @cfn.describe_stack_events(stack_name: stack_name).each do |event_page|
        event_page.stack_events.each do |event|
          yield event
        end
      end
    end
  end
end
