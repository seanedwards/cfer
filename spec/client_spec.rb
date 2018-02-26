require 'spec_helper'

describe Cfer::Cfn::Client do

  it 'fetches parameters' do
    stack = create_stack { }
    cfn = stack.client

    expect(cfn.fetch_parameters).to eq('parameter' => 'param_value', 'unchanged_key' => 'unchanged_value')
    expect(cfn.fetch_outputs).to eq('value' => 'remote_value')

    expect(cfn.fetch_parameter(cfn.name, 'parameter')).to eq('param_value')
    expect(cfn.fetch_output(cfn.name, 'value')).to eq('remote_value')
  end

  it 'has a git' do
    stack = create_stack { }
    cfn = stack.client
    expect(cfn.git).to be
  end

end
