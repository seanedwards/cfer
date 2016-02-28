description 'Example stack template for a small EC2 instance'

# NOTE: This template depends on vpc.rb

# Include common template code that will be used for examples that create EC2 instances.
include_template 'common/instance_deps.rb'

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
output :instanceip, Fn::get_att(:instance, :PublicIp)
