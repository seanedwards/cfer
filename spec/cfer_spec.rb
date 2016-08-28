require 'spec_helper'


describe Cfer do
  it 'sets descriptions' do
    stack = create_stack do
      description 'test stack'
    end

    expect(stack).to have_key :Description
    expect(stack[:Description]).to eq('test stack')
  end

  it 'reads templates from files' do
    stack = Cfer::stack_from_file('spec/support/simple_stack.rb')

    expect(stack[:Parameters]).to have_key :test
    expect(stack[:Resources]).to have_key :abc
    expect(stack[:Resources][:abc][:Type]).to eq 'Cfer::TestResource'
  end

  it 'reads templates from json files' do
    stack = Cfer::stack_from_file('spec/support/simple_stack.json')

    expect(stack[:Parameters]).to have_key :test
    expect(stack[:Resources]).to have_key :abc
    expect(stack[:Resources][:abc][:Type]).to eq 'Cfer::TestResource'
  end

  it 'includes templates from files' do
    stack = Cfer::stack_from_file('spec/support/includes_stack.rb')

    expect(stack[:Resources]).to have_key :abc
    expect(stack[:Resources][:abc][:Type]).to eq 'Cfer::TestResource'
    expect(stack[:Resources][:abc][:Properties][:Tags]).to contain_exactly 'Key' => :Name, 'Value' => 'foo'
  end

  it 'includes json templates from files' do
    stack = Cfer::stack_from_file('spec/support/includes_json_stack.rb')

    expect(stack[:Resources]).to have_key :abc
    expect(stack[:Resources][:abc][:Type]).to eq 'Cfer::TestResource'
    expect(stack[:Resources][:abc][:Properties][:Tags]).to contain_exactly 'Key' => "Name", 'Value' => 'foo'
  end

  it 'passes parameters and options' do
    stack = create_stack parameters: {:param => 'value'}, option: 'value' do
      parameter :param_value, default: parameters[:param]
      parameter :option_value, default: options[:option]
    end

    expect(stack[:Parameters][:param_value][:Default]).to eq 'value'
    expect(stack[:Parameters][:option_value][:Default]).to eq 'value'
  end

  it 'handles file and environment parameters' do
    options = {
      parameters: { 'CLIValue' => 'from_cli' },

      parameter_file: "#{__dir__}/support/parameters_stack.yaml",
      parameter_environment: 'my_env'
    }

    merged_parameters = Cfer.send(:generate_final_parameters, options)

    expect(merged_parameters['FileValue']).to eq 'from_file'
    expect(merged_parameters['EnvValue']).to eq 'from_env'
    expect(merged_parameters['CLIValue']).to eq 'from_cli'
  end

  it 'creates parameters' do
    stack = create_stack do
      parameter :test, Default: 'abc', Description: 'A test parameter'
      parameter :regex, AllowedPattern: /[abc]+123/
      parameter :list, AllowedValues: ['a', 'b', 'c']
    end

    expect(stack[:Parameters]).to have_key :test
    expect(stack[:Parameters][:test]).to have_key :Default
    expect(stack[:Parameters][:test][:Default]).to eq 'abc'
    expect(stack[:Parameters][:test][:Description]).to eq 'A test parameter'
    expect(stack[:Parameters][:test][:Type]).to eq 'String'

    expect(stack[:Parameters][:regex][:AllowedPattern]).to eq '[abc]+123'
    expect(stack[:Parameters][:list][:AllowedValues]).to eq ['a', 'b', 'c']
  end

  it 'creates outputs' do
    stack = create_stack do
      output :test, 'value'
    end

    expect(stack[:Outputs]).to have_key :test
    expect(stack[:Outputs][:test][:Value]).to eq 'value'
  end

  it 'creates resources with properties' do
    stack = create_stack do
      resource :test_resource, 'Cfer::TestResource', attribute: 'value' do
        property 'value'
        property_2 'value1', 'value2'
      end

      resource :test_resource_2, 'Cfer::TestResource' do
        other_resource Cfer::Core::Functions::Fn::ref(:test_resource)
      end
    end

    expect(stack[:Resources]).to have_key :test_resource
    expect(stack[:Resources][:test_resource][:Type]).to eq 'Cfer::TestResource'
    expect(stack[:Resources][:test_resource][:attribute]).to eq 'value'

    expect(stack[:Resources][:test_resource][:Properties][:Property]).to eq 'value'
    expect(stack[:Resources][:test_resource][:Properties][:Property2]).to eq ['value1', 'value2']

    expect(stack[:Resources][:test_resource_2][:Properties][:OtherResource]).to eq 'Ref' => :test_resource
  end

  it 'creates resources with tags' do
    stack = create_stack do
      resource :test_resource, 'Cfer::TestResource' do
        tag 'a', 'b', xyz: 'abc'
      end
    end

    expect(stack[:Resources][:test_resource][:Properties][:Tags]).to contain_exactly 'Key' => 'a', 'Value' => 'b', :xyz => 'abc'
  end

  it 'creates resources with special classes' do

    module ::CferExt::Cfer
      class TestCustomResource < Cfer::Core::Resource
        def property(value)
          actual_value value
          other_property 'abc'
          other_property_2 123
        end
      end
    end

    Cfer::Core::Resource.extend_resource "Cfer::TestPlugin" do
    end

    stack = create_stack do
      resource :test_resource, 'Cfer::TestCustomResource' do
        property 'xyz'
      end
    end

    expect(stack[:Resources][:test_resource]).to have_type CferExt::Cfer::TestCustomResource

    expect(stack[:Resources][:test_resource][:Properties]).to have_key :ActualValue
    expect(stack[:Resources][:test_resource][:Properties]).to have_key :OtherProperty
    expect(stack[:Resources][:test_resource][:Properties]).to have_key :OtherProperty2

    expect(stack[:Resources][:test_resource][:Properties][:ActualValue]).to eq 'xyz'
    expect(stack[:Resources][:test_resource][:Properties][:OtherProperty]).to eq 'abc'
    expect(stack[:Resources][:test_resource][:Properties][:OtherProperty2]).to eq 123
  end

  it 'executes hooks in the right order' do
    list = []

    Cfer::Core::Resource.before "Cfer::TestPlugin" do
      list << :before_r
    end

    Cfer::Core::Resource.after "Cfer::TestPlugin" do
      list << :after_r
    end

    Cfer::Core::Stack.before do
      list << :before_s
    end

    Cfer::Core::Stack.after do
      list << :after_s
    end

    stack = create_stack do
      resource :test_resource, 'Cfer::TestPlugin' do
        list << :during
      end
      resource :test_resource_2, 'Cfer::TestPlugin' do
        list << :during
      end
    end

    expect(list).to eq [
      :before_s,
        :before_r,
          :during,
        :after_r,
        :before_r,
          :during,
        :after_r,
      :after_s
    ]
  end
end
