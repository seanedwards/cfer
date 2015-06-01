description 'Stack template for a simple example VPC'

resource :vpc, 'AWS::EC2::VPC' do
  cidr_block '172.42.0.0/16'
  enable_dns_support true
  enable_dns_hostnames true
  instance_tenancy 'default'

  tag :DefaultVpc, true
end

resource :defaultigw, 'AWS::EC2::InternetGateway'

resource :vpcigw, 'AWS::EC2::VPCGatewayAttachment' do
  vpc_id Fn::ref(:vpc)
  internet_gateway_id Fn::ref(:defaultigw)
end

resource :routetable, 'AWS::EC2::RouteTable' do
  vpc_id Fn::ref(:vpc)
end

(1..3).each do |i|
  resource "subnet#{i}", 'AWS::EC2::Subnet' do
    availability_zone Fn::select(i, Fn::get_azs(AWS::region))
    cidr_block "172.42.#{i}.0/24"
    vpc_id Fn::ref(:vpc)
  end

  resource "srta#{i}".to_sym, 'AWS::EC2::SubnetRouteTableAssociation' do
    subnet_id Fn::ref("subnet#{i}")
    route_table_id Fn::ref(:routetable)
  end

  output "subnetid#{i}", Fn::ref("subnet#{i}")
end

resource :defaultroute, 'AWS::EC2::Route', DependsOn: [:vpcigw] do
  route_table_id Fn::ref(:routetable)
  gateway_id Fn::ref(:defaultigw)
  destination_cidr_block '0.0.0.0/0'
end

output :vpcid, Fn::ref(:vpc)


