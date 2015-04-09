module Cfer
  class Stack < Cfer::HashBuilder
    def version(v)
      aws_template_format_version v
    end

    def parameter(name, ty, d=nil)
      @parameters[name.to_s.camelize] = Cfer::build do
        type ty
        default d
      end
    end

    def resource(name, type, &block)
      clazz = "Cfer::#{type}".split('::').inject(Object) { |o, c| o.const_get c } || Cfer::Resource
      @resources[name.to_s.camelize] = Cfer::build clazz, &block
    end

    def pre_block
      @resources = {}
      @parameters = {}
    end

    def post_block
      parameters @parameters
      resources @resources
    end
  end
end
