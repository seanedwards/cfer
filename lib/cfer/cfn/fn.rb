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

    def self.base64(v)
      {"Fn::Base64" => v}
    end
  end
end
