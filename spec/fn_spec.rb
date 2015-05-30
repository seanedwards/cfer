require 'spec_helper'

describe Cfer::Cfn::Fn do

  it 'has a working ref function' do
    expect(Cfer::Cfn::Fn::ref(:abc)).to eq 'Ref' => :abc
  end

end
