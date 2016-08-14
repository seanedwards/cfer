# Utility methods to make CloudFormation functions feel more like Ruby
module Cfer::Core::Functions
  def join(sep, *args)
    {"Fn::Join" => [sep, [ *args ].flatten ]}
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

  def base64(v)
    {"Fn::Base64" => v}
  end

  def condition(cond)
    {"Condition" => cond}
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

  def get_azs(region)
    {"Fn::GetAZs" => region}
  end

  def account_id
    Fn::ref 'AWS::AccountId'
  end

  def notification_arns
    Fn::ref 'AWS::NotificationARNs'
  end

  def no_value
    Fn::ref 'AWS::NoValue'
  end

  def region
    Fn::ref 'AWS::Region'
  end

  def stack_id
    Fn::ref 'AWS::StackId'
  end

  def stack_name
    Fn::ref 'AWS::StackName'
  end
end

module Cfer::Core::Functions::AWS
  extend Cfer::Core::Functions
end

module Cfer::Core::Functions::Fn
  extend Cfer::Core::Functions
end
