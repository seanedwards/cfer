description 'Example stack template for a small EC2 instance'

# NOTE: This template depends on vpc.rb


# By not specifying a default value, a parameter becomes required.
# Specify this parameter by adding `--parameters KeyName:<ec2-keyname>` to your CLI options.
parameter :KeyName

# We define some more parameters the same way we did in the VPC template.
# Cfer will fetch the output values from the `vpc` stack we created earlier.
#
# If you created the VPC stack with a different name, you can overwrite these default values
# by adding `Vpc:<vpc_stack_name> to your `--parameters` option
parameter :Vpc, default: 'vpc'
parameter :VpcId, default: lookup_output(parameters[:Vpc], 'vpcid')
parameter :SubnetId, default: lookup_output(parameters[:Vpc], 'subnetid1')

# This is the Ubuntu 14.04 LTS HVM AMI provided by Amazon.
parameter :ImageId, default: 'ami-d05e75b8'
parameter :InstanceType, default: 't2.medium'

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

# We can define extension objects, which extend the basic JSON-building
# functionality of Cfer. Cfer provides a few of these, but you're free
# to define your own by creating a class that matches the name of an
# CloudFormation resource type, inheriting from `Cfer::AWS::Resource`
# inside the `CferExt` module:
module CferExt::AWS::EC2
  # This class adds methods to resources with the type `AWS::EC2::Instance`
  # Remember, this class could go in your own gem to be shared between your templates
  # in a way that works with the rest of your infrastructure.
  class Instance < Cfer::Cfn::Resource
    def boot_script(data)
      # This function simply wraps a bash script in the little bit of extra
      # sugar (hashbang + base64 encoding) that EC2 requires for userdata boot scripts.
      # See the AWS docs here: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
      script = <<-EOS.strip_heredoc
      #!/bin/bash
      #{data}
      EOS

      user_data Base64.encode64(script)
    end
  end
end

resource :instance, "AWS::EC2::Instance" do
  # Using the extension defined above, we can have the instance write a simple
  # file to show that it's working. When you converge this template, there
  # should be a `welcome.txt` file sitting in the `ubuntu` user's home directory.
  boot_script "echo 'Welcome to Cfer!' > /home/ubuntu/welcome.txt"

  image_id Fn::ref(:ImageId)
  instance_type Fn::ref(:InstanceType)
  key_name Fn::ref(:KeyName)

  network_interfaces [ {
      AssociatePublicIpAddress: "true",
      DeviceIndex: "0",
      GroupSet: [ Fn::ref(:instancesg) ],
      SubnetId: Fn::ref(:SubnetId)
    } ]
end

output :instance, Fn::ref(:instance)
