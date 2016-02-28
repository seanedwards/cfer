description 'Stack template for a simple example VPC'

# This template creates the following resources for a basic beginning AWS VPC setup:
#
# 1) A VPC
# 2) A route table to control network routing
# 3) An Internet gateway to route traffic to the public internet
# 4) 3 subnets, one in each of the account's first 3 availability zones
# 5) A default network route to the IGW
# 6) Associated plumbing resources to link it all together

# Parameters may be defined using the `parameter` function
parameter :VpcName, default: 'Example VPC'

# Resources are created using the `resource` function, accepting the following arguments:
# 1) The resource name (string or symbol)
# 2) The resource type. See the AWS CloudFormation docs for the available resource types: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html
resource :vpc, 'AWS::EC2::VPC' do
  # Each line within the resource block sets a single property.
  # These properties are simply camelized using the ActiveSupport gem's `camelize` function.
  # This means that the `cidr_block` function will set the `CidrBlock` property.
  cidr_block '172.42.0.0/16'

  # Following this pattern, `enable_dns_support` sets the `EnableDnsSupport` property.
  enable_dns_support true
  enable_dns_hostnames true
  instance_tenancy 'default'

  # The `tag` function is available on all resources, and adds keys to the resource's `Tags` property. It accepts the following arguments:
  # 1) Tag name (symbol or string)
  # 2) Tag value
  tag :DefaultVpc, true

  # Parameters are required at template generation time, and therefore may be referenced using the `parameters` hash anywhere in a template.
  # This will render the parameter value as a string constant in the CloudFormation JSON output
  tag :Name, parameters[:VpcName]
end

# If there are no properties to set on a resource, the block may be omitted entirely
resource :defaultigw, 'AWS::EC2::InternetGateway'

resource :vpcigw, 'AWS::EC2::VPCGatewayAttachment' do
  # Fn::ref serves the same purpose as CloudFormation's {"Ref": ""} intrinsic function.
  vpc_id Fn::ref(:vpc)
  internet_gateway_id Fn::ref(:defaultigw)
end

resource :routetable, 'AWS::EC2::RouteTable' do
  vpc_id Fn::ref(:vpc)
end

(1..2).each do |i|
  resource "subnet#{i}", 'AWS::EC2::Subnet' do
    # Other CloudFormation intrinsics, such as `Fn::Select` and `AWS::Region` are available as Ruby objects
    # Inspecting these functions will reveal that they simply return a Ruby hash representing the same CloudFormation structures
    availability_zone Fn::select(i, Fn::get_azs(AWS::region))
    cidr_block "172.42.#{i}.0/24"
    vpc_id Fn::ref(:vpc)
  end

  resource "srta#{i}".to_sym, 'AWS::EC2::SubnetRouteTableAssociation' do
    subnet_id Fn::ref("subnet#{i}")
    route_table_id Fn::ref(:routetable)
  end

  # Functions do not need to be called in any particular order.
  # The `output` function defines a stack output, which may be referenced from another stack using the `@stack_name.output_name` format
  output "subnetid#{i}", Fn::ref("subnet#{i}")
end

# The `resource` function accepts one additional parameter that was not addressed above: the options hash
# Additional options passed here will be placed inside the resource, but outside the `Properties` block.
# In this case, we've specified that the default route explicitly depends on the VPC Internet Gateway.
#   (As of this writing, this is actually a required workaround for this template,
#    because the gateway must be attached to the VPC before a route can be created to it.)
resource :defaultroute, 'AWS::EC2::Route', DependsOn: [:vpcigw] do
  route_table_id Fn::ref(:routetable)
  gateway_id Fn::ref(:defaultigw)
  destination_cidr_block '0.0.0.0/0'
end

output :vpcid, Fn::ref(:vpc)


