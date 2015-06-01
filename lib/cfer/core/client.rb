module Cfer::Core
  class Client
    def converge
      raise Cfer::Util::CferError, 'converge not implemented on this client'
    end

    def tail(options = {}, &block)
      raise Cfer::Util::CferError, 'tail not implemented on this client'
    end

    def resolve(param)
      Cfer::Cfn::ParameterValue.new(param).evaluate(self)
    end
  end
end
