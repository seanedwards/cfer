module Cfer::Cfn
  module Fn
    def self.join(sep, args)
      {"Fn::Join" => [sep, args]}
    end

    def self.ref(r)
      {"Ref" => r}
    end

    def self.get_att(r, att)
      {"Fn::GetAtt" => [r, att]}
    end

    def self.select(i, o)
      {"Fn::Select" => [i, o]}
    end
  end
end
