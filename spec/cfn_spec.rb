require 'spec_helper'

describe Cfer::Cfn::Client do

  it 'creates stacks' do
    stack = create_stack parameters: {:key => 'value'}, fetch_stack: true, times: 2 do
      parameter :key
    end
    cfn = stack.client

    expect(cfn).to receive(:validate_template)
      .exactly(1).times
      .with(template_body: stack.to_cfn) {
      double(
        capabilities: [],
        parameters: [
          double(parameter_key: 'key', no_echo: false)
        ]
      )
    }

    expect(cfn).to receive(:create_stack)
      .exactly(1).times
      .with(
        stack_name: 'test',
        template_body: stack.to_cfn,
        parameters: [
          { :parameter_key => 'key', :parameter_value => 'value', :use_previous_value => false }
        ],
        capabilities: [],
        stack_policy_body: File.read('spec/support/stack_policy.json')
      )

    Cfer::converge! cfn.name,  cfer_client: cfn, cfer_stack: stack, stack_policy: 'spec/support/stack_policy.json', output_format: 'json'
  end

  it 'updates stacks' do
    stack = create_stack parameters: { :key => 'value' }, fetch_stack: true, times: 2 do
      parameter :key
      parameter :unchanged_key

      resource :abc, "Cfer::TestResource" do
        test_param parameters[:unchanged_key]
      end
    end
    cfn = stack.client
    stack_cfn = stack.to_h

    expect(cfn).to receive(:validate_template)
      .exactly(1).times
      .with(template_body: stack.to_cfn) {
        double(
          capabilities: [],
          parameters: [
            double(parameter_key: 'key', no_echo: false, default_value: nil),
            double(parameter_key: 'unchanged_key', no_echo: false, default_value: nil)
          ]
        )
      }

    stack_options = {
      stack_name: 'test',
      template_body: stack.to_cfn,
      parameters: [
        { :parameter_key => 'key', :parameter_value => 'value', :use_previous_value => false },
        { :parameter_key => 'unchanged_key', :use_previous_value => true }
      ],
      capabilities: [],
      stack_policy_during_update_body: File.read('spec/support/stack_policy_during_update.json')
    }

    expect(cfn).to receive(:create_stack)
      .exactly(1).times
      .and_raise(Cfer::Util::StackExistsError)

    expect(cfn).to receive(:update_stack)
      .exactly(1).times
      .with(stack_options)

    expect(stack_cfn["Resources"]["abc"]["Properties"]["TestParam"]).to eq("unchanged_value")

    Cfer::converge! cfn.name,  cfer_client: cfn, cfer_stack: stack, stack_policy_during_update: 'spec/support/stack_policy_during_update.json'
  end

  it 'follows logs' do
    cfn = Cfer::Cfn::Client.new stack_name: 'test', region: 'us-east-1'
    event_list = [
      double('event 1', event_id: 1, timestamp: DateTime.now, resource_status: 'TEST', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'abcd'),
      double('event 2', event_id: 2, timestamp: DateTime.now, resource_status: 'TEST2', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'efgh'),
      double('event 3', event_id: 3, timestamp: DateTime.now, resource_status: 'TEST3', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'abcd'),
      double('event 4', event_id: 4, timestamp: DateTime.now, resource_status: 'TEST4', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'efgh'),
      double('event 5', event_id: 5, timestamp: DateTime.now, resource_status: 'TEST5', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'abcd'),
      double('event 6', event_id: 6, timestamp: DateTime.now, resource_status: 'TEST_COMPLETE', resource_type: 'Cfer::TestResource', logical_resource_id: 'test_resource', resource_status_reason: 'efgh')
    ]

    expect(cfn).to receive(:describe_stack_events)
      .exactly(3).times
      .with(stack_name: 'test')
      .and_return(
        double(stack_events: event_list.take(2).reverse),
        double(stack_events: event_list.take(4).reverse),
        double(stack_events: event_list.take(6).reverse)
      )

    expect(cfn).to receive(:describe_stacks)
      .exactly(3).times
      .with(stack_name: 'test')
      .and_return(
        double(stacks: [ double(:stack_status => 'a status') ]),
        double(stacks: [ double(:stack_status => 'TEST_COMPLETE')]),
        double(stacks: [ {:stack_status => 'TEST_COMPLETE'} ])
      )

    yielder = double('yield receiver')
    event_list.drop(1).each do |event|
      expect(yielder).to receive(:yielded).with(event)
    end

    Cfer::tail! cfn.name, cfer_client: cfn, number: 1, follow: true, no_sleep: true do |event|
      yielder.yielded event
    end

  end
end
