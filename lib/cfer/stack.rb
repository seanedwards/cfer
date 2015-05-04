module Cfer
  class Stack < Cfer::HashBuilder
    def version(v)
      set :AwsTemplateFormatVersion => v
    end

    def description(d)
      set :Description => d
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

    def resource(name, type, *args, &block)
      self[:Resources] ||= {}

      clazz = "CferExt::#{type}".split('::').inject(Object) { |o, c| o.const_get c if o && o.const_defined?(c) } || Cfer::Resource
      rc = Cfer::build clazz.new(type), options, *args, &block
      rc["Type"] = type

      self[:Resources][name] = rc
    end

    def output(name, value)
      self[:Outputs] ||= {}
      self[:Outputs][name] = {'Value' => value}
    end

    def pre_block
      @resources = {}
      @parameters = {}
      @outputs = {}
    end

    def post_block
      merge :Parameters => @parameters
      merge :Resources => @resources
      merge :Outputs => @outputs
    end
  end
end
