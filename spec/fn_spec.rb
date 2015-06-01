require 'spec_helper'

describe Cfer::Core::Fn do

  it 'has a working ref function' do
    expect(Cfer::Core::Fn::ref(:abc)).to eq 'Ref' => :abc
  end

end
