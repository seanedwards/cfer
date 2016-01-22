require 'spec_helper'

describe Cfer::Core::Fn do

  it 'has a working join function' do
    expect(Cfer::Core::Fn::join('-', ['a', 'b', 'c'])).to eq 'Fn::Join' => ['-', ['a', 'b', 'c']]
  end

  it 'has a working ref function' do
    expect(Cfer::Core::Fn::ref(:abc)).to eq 'Ref' => :abc
  end

  it 'has a working get_att function' do
    expect(Cfer::Core::Fn::get_att(:stack, :output)).to eq 'Fn::GetAtt' => [:stack, :output]
  end

  it 'has a working find_in_map function' do
    expect(Cfer::Core::Fn::find_in_map(:map_name, :key1, :key2)).to eq 'Fn::FindInMap' => [:map_name, :key1, :key2]
  end

  it 'has a working select function' do
    expect(Cfer::Core::Fn::select(:list, :item)).to eq 'Fn::Select' => [:list, :item]
  end

  it 'has a working base64 function' do
    expect(Cfer::Core::Fn::base64('value')).to eq 'Fn::Base64' => 'value'
  end

  it 'has a working condition function' do
    expect(Cfer::Core::Fn::condition(:cond)).to eq 'Condition' => :cond
  end

  it 'has a working and function' do
    expect(Cfer::Core::Fn::and(:and1, :and2, :and3)).to eq 'Fn::And' => [:and1, :and2, :and3]
  end

  it 'has a working or function' do
    expect(Cfer::Core::Fn::or(:and1, :and2, :and3)).to eq 'Fn::Or' => [:and1, :and2, :and3]
  end

  it 'has a working equals function' do
    expect(Cfer::Core::Fn::equals(:a, :b)).to eq 'Fn::Equals' => [:a, :b]
  end

  it 'has a working if function' do
    expect(Cfer::Core::Fn::if(:cond, :truthy, :falsy)).to eq 'Fn::If' => [:cond, :truthy, :falsy]
  end

  it 'has a working not function' do
    expect(Cfer::Core::Fn::not(:expr)).to eq 'Fn::Not' => [:expr]
  end

  it 'has a working get_azs function' do
    expect(Cfer::Core::Fn::get_azs(:region)).to eq 'Fn::GetAZs' => :region
  end

  it 'has a working AccountID intrinsic' do
    expect(Cfer::Cfn::AWS::account_id).to eq 'Ref' => 'AWS::AccountId'
  end

  it 'has a working NotificationARNs intrinsic' do
    expect(Cfer::Cfn::AWS::notification_arns).to eq 'Ref' => 'AWS::NotificationARNs'
  end

  it 'has a working NoValue intrinsic' do
    expect(Cfer::Cfn::AWS::no_value).to eq 'Ref' => 'AWS::NoValue'
  end

  it 'has a working Region intrinsic' do
    expect(Cfer::Cfn::AWS::region).to eq 'Ref' => 'AWS::Region'
  end

  it 'has a working StackId intrinsic' do
    expect(Cfer::Cfn::AWS::stack_id).to eq 'Ref' => 'AWS::StackId'
  end

  it 'has a working StackName intrinsic' do
    expect(Cfer::Cfn::AWS::stack_name).to eq 'Ref' => 'AWS::StackName'
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
