module Cfer::Core::Fn
  class << self
    def join(sep, args)
      {"Fn::Join" => [sep, args]}
    end

    def ref(r)
      {"Ref" => r}
    end

    def get_att(r, att)
      {"Fn::GetAtt" => [r, att]}
    end

    def select(i, o)
      {"Fn::Select" => [i, o]}
    end

    def base64(v)
      {"Fn::Base64" => v}
    end

    def condition(cond)
      {"Condition" => cond}
    end

    def and(conds)
      {"Fn::And" => [conds]}
    end

    def equals(a, b)
      {"Fn::Equals" => [a, b]}
    end

    def if(cond, t, f)
      {"Fn::If" => [cond, t, f]}
    end

    def not(cond)
      {"Fn::Not" => cond}
    end

    def or(conds)
      {"Fn::Or" => conds}
    end

    def get_azs(region)
      {"Fn::GetAZs" => region}
    end
  end
end
