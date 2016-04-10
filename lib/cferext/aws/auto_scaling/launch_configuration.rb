module CferExt::AWS::AutoScaling
  class LaunchConfiguration < Cfer::Core::Resource
  end

  class AutoScalingGroup < Cfer::Core::Resource
    def desired_size(size)
      desired_capacity size
    end
  end
end
