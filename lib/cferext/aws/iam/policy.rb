require 'cferext/aws/iam/policy_generator'

Cfer::Core::Resource.extend_resource "AWS::IAM::ManagedPolicy" do
  include CferExt::AWS::IAM::WithPolicyDocument
end

Cfer::Core::Resource.extend_resource "AWS::IAM::User" do
  include CferExt::AWS::IAM::WithPolicies
end

Cfer::Core::Resource.extend_resource "AWS::IAM::Group" do
  include CferExt::AWS::IAM::WithPolicies
end

Cfer::Core::Resource.extend_resource "AWS::IAM::Role" do
  include CferExt::AWS::IAM::WithPolicies

  def assume_role_policy_document(doc = nil, &block)
    doc = CferExt::AWS::IAM.generate_policy(&block) if doc == nil
    properties :AssumeRolePolicyDocument => doc
  end
end

Cfer::Core::Resource.extend_resource "AWS::IAM::Policy" do
  def policy_document(doc = nil, &block)
    doc = CferExt::AWS::IAM.generate_policy(&block) if doc == nil
    properties :PolicyDocument => doc
  end
end

