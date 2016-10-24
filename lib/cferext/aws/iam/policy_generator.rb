require 'docile'

module CferExt
  module AWS
    module IAM
      class PolicyGenerator < Cfer::BlockHash
        def initialize
          self[:Version] = '2012-10-17'
          self[:Statement] = []
        end

        def statement(options = {}, &block)
          statement = ::Cfer::BlockHash.new(&block)
          statement.merge! options
          statement.build_from_block(&block)
          self[:Statement].unshift statement
        end

        def allow(&block)
          statement Effect: :Allow, &block
        end

        def deny(&block)
          statement Effect: :Deny, &block
        end
      end

      module WithPolicyDocument
        def policy_document(doc = nil, &block)
          doc = CferExt::AWS::IAM.generate_policy(&block) if doc == nil
          self[:Properties][:PolicyDocument] = doc
        end
      end

      module WithPolicies
        def policy(name, doc = nil, &block)
          self[:Properties][:Policies] ||= []
          doc = CferExt::AWS::IAM.generate_policy(&block) if doc == nil
          get_property(:Policies) << {
            PolicyName: name,
            PolicyDocument: doc
          }
        end
      end

      def self.generate_policy(&block)
        policy = PolicyGenerator.new
        policy.build_from_block(&block)
        policy
      end

      EC2_ASSUME_ROLE_POLICY_DOCUMENT =
        CferExt::AWS::IAM.generate_policy do
          allow do
            principal Service: 'ec2.amazonaws.com'
            action 'sts:AssumeRole'
          end
        end.freeze
    end
  end
end
