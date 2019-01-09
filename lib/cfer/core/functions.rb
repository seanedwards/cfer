# Utility methods to make CloudFormation functions feel more like Ruby
module Cfer::Core::Functions
  def join(sep, *args)
    {"Fn::Join" => [sep, [ *args ].flatten ]}
  end

  def split(sep, str)
    {"Fn::Split" => [sep, str ]}
  end

  def ref(r)
    {"Ref" => r}
  end

  def get_att(r, att)
    {"Fn::GetAtt" => [r, att]}
  end

  def find_in_map(map_name, key1, key2)
    {"Fn::FindInMap" => [map_name, key1, key2]}
  end

  def select(i, o)
    {"Fn::Select" => [i, o]}
  end

  def and(*conds)
    {"Fn::And" => conds}
  end

  def or(*conds)
    {"Fn::Or" => conds}
  end

  def equals(a, b)
    {"Fn::Equals" => [a, b]}
  end

  def if(cond, t, f)
    {"Fn::If" => [cond, t, f]}
  end

  def not(cond)
    {"Fn::Not" => [cond]}
  end

  def get_azs(region = '')
    {"Fn::GetAZs" => region}
  end

  def split(*args)
    {"Fn::Split" => [ *args ].flatten }
  end
  
  def cidr(ip_block, count, size_mask)
    {"Fn::Cidr" => [ip_block, count, size_mask]}
  end

  def sub(str, vals = {})
    {"Fn::Sub" => [str, vals]}
  end

  def notification_arns
    ref 'AWS::NotificationARNs'
  end
end

module Cfer::Core::Functions::AWS
  extend Cfer::Core::Functions

  def self.method_missing(sym, *args)
    method = sym.to_s.camelize
    raise "AWS::#{method} does not accept arguments" unless args.empty?
    ref "AWS::#{method}"
  end
end

module Cfer::Core::Functions::Fn
  extend Cfer::Core::Functions

  def self.method_missing(sym, *args)
    method = sym.to_s.camelize
    raise "Fn::#{method} requires one argument" unless args.size == 1
    { "Fn::#{method}" => args.first }
  end
end
