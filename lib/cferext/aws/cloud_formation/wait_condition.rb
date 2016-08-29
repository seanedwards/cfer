Cfer::Core::Resource.extend_resource 'AWS::CloudFormation::WaitCondition' do
  def timeout(t)
    properties :Timeout => t
  end
end

