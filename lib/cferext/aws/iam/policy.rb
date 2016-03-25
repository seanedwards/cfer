require_relative 'policy_generator.rb'

module CferExt
  module AWS
    module IAM

      class ManagedPolicy < Cfer::Cfn::Resource
        include WithPolicyDocument
      end

      class User < Cfer::Cfn::Resource
        include WithPolicies
      end

      class Group < Cfer::Cfn::Resource
        include WithPolicies
      end

      class Role < Cfer::Cfn::Resource
        include WithPolicies

        def assume_role_policy_document(doc = nil, &block)
          doc = CferExt::AWS::IAM.generate_policy(&block) if doc == nil
          properties :AssumeRolePolicyDocument => doc
        end
      end

      class Policy < Cfer::Cfn::Resource
        def policy_document(doc = nil, &block)
          doc = CferExt::AWS::IAM.generate_policy(&block) if doc == nil
          properties :PolicyDocument => doc
        end
      end
    end
  end
end
