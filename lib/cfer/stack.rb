module Cfer
  class Stack < Cfer::HashBuilder
    def version(v)
      aws_template_format_version v
    end

    def parameter(name, options = {}, d=nil)
      options[:type] ||= 'String'
      options[:description] ||= "#{name} parameter"
      param = {}
      options.each do |k, v|
        param[k.to_s.camelize] = v
      end
      @parameters[name.to_s.camelize] = param
    end

    def resource(name, type, &block)
      clazz = "Cfer::#{type}".split('::').inject(Object) { |o, c| o.const_get c if o && o.const_defined?(c) } || Cfer::Resource
      @resources[name.to_s.camelize] = Cfer::build clazz, &block
    end

    def output(name, value)
      @outputs[name.to_s.camelize] = {'Value' => value}
    end

    def pre_block
      @resources = {}
      @parameters = {}
      @outputs = {}
    end

    def post_block
      parameters @parameters
      resources @resources
      outputs @outputs
    end
  end
end
