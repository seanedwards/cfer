description 'Example stack template for a small EC2 instance'

# NOTE: This template depends on vpc.rb

# Include common template code that will be used for examples that create EC2 instances.
include_template 'common/instance_deps.rb'

resource :instance, "AWS::EC2::Instance",
  # Set a creation policy so that the stack will wait for
  # on-instance provisioning to complete before marking the instance
  # as done.
  :CreationPolicy => {
    :ResourceSignal => {
      :Count => 1
    }
  } do
  # Chef provisioning depends on cfn-init, so set that up first.
  # We will have the initial provisioning set up cfn-hup, install chef, and run our cookbooks.
  # Cfn-hup will only rerun chef when the metadata changes.
  cfn_init_setup signal: :instance,
    cfn_init_config_set: [ :cfn_hup, :install_chef, :run_chef],
    cfn_hup_config_set: [ :cfn_hup, :run_chef]

  # Configure chef to generate a Berksfile that will download the AWS cookbook from the Chef supermarket.
  # Set the run list to run the AWS cookbook, so our instance will have the AWS SDK available.
  chef_solo version: 'latest',
    node: {
      cfer: {
        demo: {
          welcome: "Welcome to Cfer!"
        }
      },
      run_list: 'recipe[ec2-demo]'
    },
    # We specify a berksfile inline, but you could read this from somewhere else in your repo too.
    # This uses a simple cookbook to write a file, similar to the instance.rb example.
    # Review this cookbook here: https://github.com/seanedwards/cfer-cookbook-demo
    berksfile: <<-EOF
      source "https://supermarket.chef.io"
      puts ENV
      cookbook 'ec2-demo', github: 'seanedwards/cfer-cookbook-demo', branch: 'master'
    EOF

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
