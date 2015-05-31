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


  it 'follows logs' do
    cfn = double("cfn")
    yielder = double('yield receiver')

    event_list = [
      double(event_id: 1234, timestamp: DateTime.now, resource_status: 'TEST', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'abcd'),
      double(event_id: 5678, timestamp: DateTime.now, resource_status: 'TEST2', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'efgh'),
    ]

    event_list_2 = [
      double(event_id: 1234, timestamp: DateTime.now, resource_status: 'TEST', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'abcd'),
      double(event_id: 5678, timestamp: DateTime.now, resource_status: 'TEST2', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'efgh'),
    ]

    event_list_3 = [
      double(event_id: 1234, timestamp: DateTime.now, resource_status: 'TEST', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'abcd'),
      double(event_id: 5678, timestamp: DateTime.now, resource_status: 'TEST_COMPLETE', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'efgh'),
    ]

    expect(cfn).to receive(:describe_stack_events)
      .exactly(3).times
      .with(stack_name: 'test')
      .and_return(
        [ double(stack_events: event_list) ],
        [ double(stack_events: event_list_2) ],
        [ double(stack_events: event_list_3) ]
      )

    expect(cfn).to receive(:describe_stacks)
      .exactly(2).times
      .with(stack_name: 'test')
      .and_return(
        double(stacks: [ double(stack_status: 'a status') ]),
        double(stacks: [ double(stack_status: 'TEST_COMPLETE')])
      )

    expect(yielder).to receive(:yielded).with(event_list.first)

    Cfer::Cfn::CfnStack.new('test', cfn).tail(number: 1, follow: true) do |event|
      yielder.yielded event
    end

  end
end
