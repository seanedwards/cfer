require 'spec_helper'

describe Cfer do
  it 'builds stacks' do
    h = Cfer.stack do
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

end
