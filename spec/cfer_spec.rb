require 'spec_helper'

describe Cfer do
  it 'sets descriptions' do
    stack = create_stack do
      description 'test stack'
    end

    expect(stack).to have_key :Description
    expect(stack[:Description]).to eq('test stack')
  end

  it 'creates parameters' do
    stack = create_stack do
      parameter :test, Default: 'abc'
    end

    expect(stack[:Parameters]).to have_key :test
    expect(stack[:Parameters][:test]).to have_key :Default
    expect(stack[:Parameters][:test][:Default]).to eq 'abc'
    expect(stack[:Parameters][:test][:Type]).to eq 'String'
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
        other_resource test_resource
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

end
