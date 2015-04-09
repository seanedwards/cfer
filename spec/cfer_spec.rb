require 'spec_helper'

module CferExt
  module A
    class B < Cfer::Resource
      def c(e)
        d e
      end

      def pre_block
        super
        k "l"
      end

      def post_block
        i "j"
        super
      end
    end
  end
end

describe Cfer do
  it 'builds equivalent hashes' do
    h = Cfer::build do
      a "b"
    end
    expect(h).to have_key :A
  end

  it 'builds recursive hashes' do
    h = Cfer::build do
      a do
        b "c"
      end
    end
    expect(h).to have_key :A
    expect(h[:A]).to have_key :B
  end

  it 'builds stacks' do
    h = Cfer::stack do
      version 'v'
      resource :r, "A::B" do
        c "e"
        tag "x", "y"
      end
    end

    expect(h).to have_key :Resources
    expect(h[:Resources]).to have_key :R
    expect(h[:Resources][:R]).to have_key :D
    expect(h[:Resources][:R][:D]).to eq("e")

    expect(h[:Resources][:R]).to have_key :I
    expect(h[:Resources][:R][:I]).to eq("j")

    expect(h[:Resources][:R]).to have_key :K
    expect(h[:Resources][:R][:K]).to eq("l")

    expect(h[:Resources][:R]).to have_key :Properties
    expect(h[:Resources][:R][:Properties]).to have_key :Tags

  end

end
