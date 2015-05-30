module Cfer::Cfn::AWS
  class << self
    include Cfer::Cfn
    def account_id
      Fn::ref 'AWS::AccountId'
    end

    def notification_arns
      Fn::ref 'AWS::NotificationARNs'
    end

    def no_value
      Fn::ref 'AWS::NoValue'
    end

    def region
      Fn::ref 'AWS::Region'
    end

    def stack_id
      Fn::ref 'AWS::StackId'
    end

    def stack_name
      Fn::ref 'AWS::StackName'
    end
  end
end

