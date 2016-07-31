require 'spec_helper'

Cfer::Core::Resource.extend_resource 'Cfer::CustomResource' do
  def test_value(val)
    properties TestValue: val
    properties TestValue2: val
  end
end

Cfer::Core::Resource.before 'Cfer::CustomResource' do
  properties BeforeValue: 1234
end

Cfer::Core::Resource.before 'Cfer::CustomResource' do
  properties AfterValue: 5678
end

def describe_resource(type, &block)
  stack = create_stack do
    resource :test_resource, type do
      instance_eval(&block)
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
    expect(rc[:TestValue]).to eq "asdf"
    expect(rc[:TestValue2]).to eq "asdf"
    expect(rc[:AfterValue]).to eq 5678
  end

  it 'extends AWS::CloudFormation::WaitCondition' do
    rc = describe_resource 'AWS::CloudFormation::WaitCondition' do
      timeout 100
    end

    expect(rc[:Timeout]).to eq 100
  end

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
end
