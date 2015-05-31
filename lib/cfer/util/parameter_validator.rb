module Cfer::Util
  class ParameterValue

    def initialize(val)
      @val = val
    end

    def to_s
      @val.to_s
    end

    def raw
      @val
    end

    def is_lookup_param?
      @val.starts_with? '@'
    end

    def evaluate(cfn_client)
      # See if the value follows the form @<stack>.<output>
      m = /^@(.+?)\.(.+)$/.match(@val)

      if m
        @remote_val ||= fetch_output(cfn_client, m[1], m[2])
      else
        @val
      end
    end

    private
    def fetch_output(cfn_client, stack_name, output_name)
      cfn_client.stack_cache[stack_name] ||= cfn_client.describe_stacks(stack_name: stack_name)

      output = cfn_client.stack_cache[stack_name].stacks.first.outputs.find do |o|
        o.output_key == output_name
      end

      if output
        output.output_value
      else
        raise CferError.new("Stack #{stack_name} has no output value named `#{output_name}`")
      end
    end
  end

  class ParameterValidator
    def initialize(params)
      @parameters = HashWithIndifferentAccess.new
      params.each do |k, v|
        @parameters[k] = ParameterValue.new(v)
      end
    end

    def [](key)
      @parameters[key]
    end

  end
end
