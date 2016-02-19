require 'cferext/provisioning'

require 'base64'
require 'yaml'

module CferExt::AWS::AutoScaling
  class LaunchConfiguration < Cfer::Cfn::Resource
    include CferExt::Provisioning

    def initialize(name, type, options = {}, &block)
      options[:Metadata] ||= {}
      super(name, type, options, &block)
    end
  end
end
