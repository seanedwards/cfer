# By not specifying a default value, a parameter becomes required.
# Specify this parameter by adding `--parameters KeyName:<ec2-keyname>` to your CLI options.
parameter :KeyName

# We define some more parameters the same way we did in the VPC template.
# Cfer will fetch the output values from the `vpc` stack we created earlier.
#
# If you created the VPC stack with a different name, you can overwrite these default values
# by adding `Vpc:<vpc_stack_name> to your `--parameters` option
parameter :Vpc, default: 'vpc'
parameter :VpcId, default: (lookup_output(parameters[:Vpc], 'vpcid') rescue nil)
parameter :SubnetId, default: (lookup_output(parameters[:Vpc], 'subnetid1') rescue nil)

# This is the Ubuntu 14.04 LTS HVM AMI provided by Amazon.
parameter :ImageId, default: 'ami-fce3c696'
parameter :InstanceType, default: 't2.micro'

# Define a security group to be applied to an instance.
# This one will allow SSH access from anywhere, and no other inbound traffic.
resource :instancesg, "AWS::EC2::SecurityGroup" do
  group_description 'Wide-open SSH'
  vpc_id Fn::ref(:VpcId)

  # Parameter values can be Ruby arrays and hashes. These will be transformed to JSON.
  # You could write your own functions to make stuff like this easier, too.
  security_group_ingress [
    {
      CidrIp: '0.0.0.0/0',
      IpProtocol: 'tcp',
      FromPort: 22,
      ToPort: 22
    }
  ]
end
