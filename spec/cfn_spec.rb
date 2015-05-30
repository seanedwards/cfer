require 'spec_helper'

describe Cfer::Cfn::CfnStack do
  it 'validates parameters' do
    cfn = double("cfn")

    stack = create_stack key: 'value' do
      parameter :key
    end

    expect(cfn).to receive(:validate_template).with(template_body: stack.to_cfn) {
      double(
        capabilities: [],
        parameters: [
          double(parameter_key: 'key', no_echo: false)
        ]
      )
    }

    expect(cfn).to receive(:create_stack).with(
      stack_name: 'test',
      template_body: stack.to_cfn,
      parameters: [
        { :ParameterKey => 'key', :ParameterValue => 'value', :UsePreviousValue => false }
      ],
      capabilities: []
    )

    Cfer::Cfn::CfnStack.new('test', cfn).converge stack
  end
end
