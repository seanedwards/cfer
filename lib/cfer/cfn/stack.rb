module Cfer::Cfn
  class Stack < Cfer::Block
    include Cfer::Cfn

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

      rc = Cfer::Cfn::Resource.new(type, options, &block)

      self[:Resources][name] = rc
    end

    def output(name, value)
      self[:Outputs] ||= {}

      self[:Outputs][name] = {'Value' => value}
    end
  end
end
