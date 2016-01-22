require 'cferext/provisioning'

require 'base64'
require 'yaml'

module CferExt::AWS::EC2
  class Instance < Cfer::Cfn::Resource
    include CferExt::Provisioning

    def initialize(name, type, options = {}, &block)
      options[:Metadata] ||= {}
      super(name, type, options, &block)
    end
  end
end
