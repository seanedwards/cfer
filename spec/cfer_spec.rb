require 'spec_helper'

def create_stack(&block)
  s = Cfer.stack(&block)
  pp s.to_h
  s
end

describe Cfer do
  it 'builds stacks' do
    h = create_stack do
      version 'v'
      parameter :A
      parameter :B, Type: :number
      resource :R, "A::B" do
        c "e"
        tag "x", "y"
      end
    end
    h = h.to_h

    puts h

    expect(h).to have_key "Resources"
    expect(h["Resources"]).to have_key "R"

    expect(h["Resources"]["R"]).to have_key "Type"
    expect(h["Resources"]["R"]["Type"]).to eq "A::B"

    expect(h["Resources"]["R"]).to have_key "Properties"
    expect(h["Resources"]["R"]["Properties"]["C"]).to eq("e")
    expect(h["Resources"]["R"]["Properties"]).to have_key "Tags"

  end

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
    end

    expect(stack[:Resources]).to have_key :test_resource
    expect(stack[:Resources][:test_resource][:Type]).to eq 'Cfer::TestResource'
    expect(stack[:Resources][:test_resource][:attribute]).to eq 'value'

    expect(stack[:Resources][:test_resource][:Properties][:Property]).to eq 'value'
    expect(stack[:Resources][:test_resource][:Properties][:Property2]).to eq ['value1', 'value2']

    expect(stack[:Resources][:test_resource].property).to eq 'value'
    expect(stack[:Resources][:test_resource].property2).to eq ['value1', 'value2']
  end

end
