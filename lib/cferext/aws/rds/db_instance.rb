Cfer::Core::Resource.extend_resource 'AWS::RDS::DBInstance' do
  def vpc_security_groups(groups)
    properties :VPCSecurityGroups => groups
  end
end
