description 'Stack template for VPC'

parameter :VpcId, default: '@vpc.vpcid'
parameter :SubnetId, default: '@vpc.subnetid1'
parameter :KeyName
parameter :ImageId, default: 'ami-d05e75b8'

resource :instancesg, "AWS::EC2::SecurityGroup" do
  group_description 'Wide-open SSH'
  vpc_id Fn::ref(:VpcId)
  security_group_ingress [
    {
      CidrIp: '0.0.0.0/0',
      IpProtocol: 'tcp',
      FromPort: 22,
      ToPort: 22
    }
  ]
end

resource :instance, "AWS::EC2::Instance" do
  subnet_id Fn::ref(:SubnetId)
  image_id Fn::ref(:ImageId)
  instance_type 't2.medium'
  key_name Fn::ref(:KeyName)
  security_group_ids [ Fn::ref(:instancesg) ]

  #provision do
  #  in_dir '/opt' do
  #    git 'git@github.com:eropple/asger.git'
  #  end
  #end
end

output :instance, Fn::ref(:instance)
