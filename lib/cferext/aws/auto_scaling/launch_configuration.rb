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

  class AutoScalingGroup < Cfer::Cfn::Resource
    def desired_size(size)
      desired_capacity size
    end
  end
end
