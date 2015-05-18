
module CferExt::AWS::EC2
  class Instance < Cfer::Cfn::Resource
    def initialize(type, options = {}, &block)
      options[:Metadata] ||= {}
      super(type, options, &block)
    end

    def provision(type, options = {}, &block)
      clazz = "CferExt::Provisioning::#{type.to_s.camelize}".split('::').inject(Object) { |o, c| o.const_get c if o && o.const_defined?(c) } || raise("No such provisioner #{type}")
      provisioner = clazz.new(options)
      Docile.dsl_eval(provisioner, options, &block)
      provisioner.apply(self)
    end
  end
end
