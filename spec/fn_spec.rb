require 'spec_helper'

describe Cfer::Core::Fn do
  cfn = Cfer::Cfn::Client.new stack_name: 'test', region: 'us-east-1'

  it 'has a working ref function' do
    expect(Cfer::Core::Fn::ref(:abc)).to eq 'Ref' => :abc
  end

  it 'has a working lookup function' do
    setup_describe_stacks cfn, 'other_stack'

    stack = create_stack client: cfn do
      resource :abc, "Cfer::TestResource" do
        test_param lookup_output("other_stack", "value")
      end
    end

    stack_cfn = stack.to_h

    expect(stack_cfn["Resources"]["abc"]["Properties"]["TestParam"]).to eq("remote_value")
  end

end
