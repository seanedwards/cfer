require 'cferext/aws/iam/policy_generator'

module CferExt
  module AWS
    module IAM

      class ManagedPolicy < Cfer::Core::Resource
        include WithPolicyDocument
      end

      class User < Cfer::Core::Resource
        include WithPolicies
      end

      class Group < Cfer::Core::Resource
        include WithPolicies
      end

      class Role < Cfer::Core::Resource
        include WithPolicies

        def assume_role_policy_document(doc = nil, &block)
          doc = CferExt::AWS::IAM.generate_policy(&block) if doc == nil
          properties :AssumeRolePolicyDocument => doc
        end
      end

      class Policy < Cfer::Core::Resource
        def policy_document(doc = nil, &block)
          doc = CferExt::AWS::IAM.generate_policy(&block) if doc == nil
          properties :PolicyDocument => doc
        end
      end
    end
  end
end
