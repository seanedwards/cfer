require 'spec_helper'

FUNCTIONS = Cfer::Core::Functions

describe Cfer::Core::Functions do

  it 'has a working join function' do
    expect(FUNCTIONS::Fn::join('-', ['a', 'b', 'c'])).to eq 'Fn::Join' => ['-', ['a', 'b', 'c']]
    expect(FUNCTIONS::Fn::join('-', 'a', 'b', 'c')).to eq 'Fn::Join' => ['-', ['a', 'b', 'c']]
  end

  it 'has a working ref function' do
    expect(FUNCTIONS::Fn::ref(:abc)).to eq 'Ref' => :abc
  end

  it 'has a working get_att function' do
    expect(FUNCTIONS::Fn::get_att(:stack, :output)).to eq 'Fn::GetAtt' => [:stack, :output]
  end

  it 'has a working find_in_map function' do
    expect(FUNCTIONS::Fn::find_in_map(:map_name, :key1, :key2)).to eq 'Fn::FindInMap' => [:map_name, :key1, :key2]
  end

  it 'has a working select function' do
    expect(FUNCTIONS::Fn::select(:list, :item)).to eq 'Fn::Select' => [:list, :item]
  end

  it 'has a working base64 function' do
    expect(FUNCTIONS::Fn::base64('value')).to eq 'Fn::Base64' => 'value'
  end

  it 'has a working condition function' do
    expect(FUNCTIONS::Fn::condition(:cond)).to eq 'Condition' => :cond
  end

  it 'has a working and function' do
    expect(FUNCTIONS::Fn::and(:and1, :and2, :and3)).to eq 'Fn::And' => [:and1, :and2, :and3]
  end

  it 'has a working or function' do
    expect(FUNCTIONS::Fn::or(:and1, :and2, :and3)).to eq 'Fn::Or' => [:and1, :and2, :and3]
  end

  it 'has a working equals function' do
    expect(FUNCTIONS::Fn::equals(:a, :b)).to eq 'Fn::Equals' => [:a, :b]
  end

  it 'has a working if function' do
    expect(FUNCTIONS::Fn::if(:cond, :truthy, :falsy)).to eq 'Fn::If' => [:cond, :truthy, :falsy]
  end

  it 'has a working not function' do
    expect(FUNCTIONS::Fn::not(:expr)).to eq 'Fn::Not' => [:expr]
  end

  it 'has a working get_azs function' do
    expect(FUNCTIONS::Fn::get_azs(:region)).to eq 'Fn::GetAZs' => :region
  end

  it 'has a working AccountID intrinsic' do
    expect(FUNCTIONS::AWS::account_id).to eq 'Ref' => 'AWS::AccountId'
  end

  it 'has a working NotificationARNs intrinsic' do
    expect(FUNCTIONS::AWS::notification_arns).to eq 'Ref' => 'AWS::NotificationARNs'
  end

  it 'has a working NoValue intrinsic' do
    expect(FUNCTIONS::AWS::no_value).to eq 'Ref' => 'AWS::NoValue'
  end

  it 'has a working Region intrinsic' do
    expect(FUNCTIONS::AWS::region).to eq 'Ref' => 'AWS::Region'
  end

  it 'has a working StackId intrinsic' do
    expect(FUNCTIONS::AWS::stack_id).to eq 'Ref' => 'AWS::StackId'
  end

  it 'has a working StackName intrinsic' do
    expect(FUNCTIONS::AWS::stack_name).to eq 'Ref' => 'AWS::StackName'
  end

  it 'has a working lookup function' do
    cfn = Cfer::Cfn::Client.new(stack_name: 'test', region: 'us-east-1')
    setup_describe_stacks cfn, 'other_stack'
    stack = create_stack client: cfn, fetch_stack: true do
      resource :abc, "Cfer::TestResource" do
        test_param lookup_output("other_stack", "value")
      end
    end

    stack_cfn = stack.to_h

    expect(stack_cfn["Resources"]["abc"]["Properties"]["TestParam"]).to eq("remote_value")
  end

end
