$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pp'
require 'aws-sdk'
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

Aws.config[:stub_responses] = true

def create_stack(options = {}, &block)
  cfn = options[:client] || Cfer::Cfn::Client.new(stack_name: options[:stack_name] || 'test', region: 'us-east-1')
  setup_describe_stacks cfn, cfn.name, options[:times] || 1
  cfn.fetch_stack

  s = Cfer.stack_from_block(options.merge(client: cfn), &block)
  pp s.to_h
  s
end

def setup_describe_stacks(cfn, stack_name = 'test', times = 1)
  allow(cfn).to receive(:describe_stacks)
    .with(stack_name: stack_name)
    .and_return(
      double(
        stacks: double(
          first: double(
            to_h: {
              :stack_status => 'CREATE_COMPLETE',
              :parameters => [
                {
                  :parameter_key => 'parameter',
                  :parameter_value => 'param_value'
                },
                {
                  :parameter_key => 'unchanged_key',
                  :parameter_value => 'unchanged_value'
                }
              ],
              :outputs => [
                {
                  :output_key => 'value',
                  :output_value => 'remote_value'
                }
              ]
            }
          )
        )
      )
    )

  allow(cfn).to receive(:get_template_summary)
   .with(stack_name: stack_name)
   .and_return(
     double(
       metadata: "{}"
     )
   )
end

module Cfer
  DEBUG = true
end

require 'cfer'

Cfer::LOGGER.level = Logger::DEBUG

