require 'spec_helper'

Cfer::Core::Resource.extend_resource 'Cfer::CustomResource' do
  def test_value(val)
    properties TestValue: val
    properties TestValue2: val
  end
end

Cfer::Core::Resource.before 'Cfer::CustomResource', nice: 10 do
  properties BeforeValue2: get_property(:BeforeValue)
end

Cfer::Core::Resource.before 'Cfer::CustomResource' do
  properties BeforeValue: 1234
end

Cfer::Core::Resource.after 'Cfer::CustomResource', nice: 10 do
  properties AfterValue2: get_property(:AfterValue)
end

Cfer::Core::Resource.after 'Cfer::CustomResource' do
  properties AfterValue: get_property(:TestValue2)
end

def describe_resource(type, &block)
  stack = create_stack do
    resource :test_resource, type do
      build_from_block(&block)
    end
  end

  stack[:Resources][:test_resource][:Properties]
end

describe CferExt do
  it 'supports custom resources' do
    rc = describe_resource 'Cfer::CustomResource' do
      test_value "asdf"
    end

    expect(rc[:BeforeValue]).to eq 1234
    expect(rc[:BeforeValue2]).to eq 1234
    expect(rc[:TestValue]).to eq "asdf"
    expect(rc[:TestValue2]).to eq "asdf"
    expect(rc[:AfterValue]).to eq "asdf"
    expect(rc[:AfterValue2]).to eq "asdf"
  end

  # TODO: Why does this break on Ruby 2?
  #it 'extends AWS::CloudFormation::WaitCondition' do
  #  rc = describe_resource 'AWS::CloudFormation::WaitCondition' do
  #    timeout 100
  #  end
  #
  #  expect(rc[:Timeout]).to eq 100
  #end

  it 'extends AWS::RDS::DBInstance' do
    rc = describe_resource 'AWS::RDS::DBInstance' do
      vpc_security_groups :asdf
    end

    expect(rc[:VPCSecurityGroups]).to eq :asdf
  end

  it 'extends AWS::AutoScaling::AutoScalingGroup' do
    rc = describe_resource 'AWS::AutoScaling::AutoScalingGroup' do
      desired_size 1
    end

    expect(rc[:DesiredCapacity]).to eq 1
  end

  it 'extends AWS::RDS::DBInstance' do
    rc = describe_resource 'AWS::RDS::DBInstance' do
      vpc_security_groups :asdf
    end

    expect(rc[:VPCSecurityGroups]).to eq :asdf
  end

  it 'extends AWS::KMS::Key' do
    rc = describe_resource 'AWS::KMS::Key' do
      key_policy do
        statement do
          effect :Allow
          principal AWS: "arn:aws:iam::123456789012:user/Alice"
          action '*'
          resource '*'
        end
      end
    end

    expect(rc[:KeyPolicy][:Statement].first[:Effect]).to eq(:Allow)
  end

  it 'extends AWS::IAM::User, Group and Role' do
    %w{User Group Role}.each do |type|

      rc = describe_resource "AWS::IAM::#{type}" do
        policy :test_policy do
          statement {
            effect :Allow
            principal AWS: "arn:aws:iam::123456789012:user/Alice"
            action '*'
            resource '*'
          }
        end
      end
      expect(rc[:Policies].first[:PolicyName]).to eq(:test_policy)
      expect(rc[:Policies].first[:PolicyDocument][:Statement].first[:Effect]).to eq(:Allow)
    end
  end

  it 'extends AWS::IAM::Role' do
    rc = describe_resource "AWS::IAM::Role" do
      assume_role_policy_document do
        allow do
          principal Service: 'ec2.amazonaws.com'
          action 'sts:AssumeRole'
        end
      end
    end

    expect(rc[:AssumeRolePolicyDocument]).to eq(CferExt::AWS::IAM::EC2_ASSUME_ROLE_POLICY_DOCUMENT)
  end

  it 'extends AWS::IAM::Policy' do
    rc = describe_resource "AWS::IAM::Policy" do
      policy_document do
        statement {
          effect :Allow
          principal AWS: "arn:aws:iam::123456789012:user/Alice"
          action '*'
          resource '*'
        }
      end
    end
    expect(rc[:PolicyDocument][:Statement].first[:Effect]).to eq(:Allow)
  end
  it 'extends AWS::Route53::RecordSetGroup' do
    results = []

    rc = describe_resource "AWS::Route53::RecordSetGroup" do
      %w{a aaaa cname mx ns ptr soa spf srv txt}.each do |type|
        self.send type, "#{type}.test.com", "record #{type}"
        results << {
          Type: type.upcase,
          Name: "#{type}.test.com",
          ResourceRecords: [ "record #{type}" ]
        }
      end
    end

    expect(rc[:RecordSets]).to eq(results)
  end
end
