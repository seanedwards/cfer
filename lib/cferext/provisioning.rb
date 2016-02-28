module CferExt::Provisioning
  def cloud_config(options)
    data = ::YAML.dump(cloud_init_data.stringify_keys)
    user_data Cfer::Core::Fn::base64("#cloud-config\n##{data}")
  end

  def shell_init(script, options = {})
    data = "#!#{options[:shell] || '/usr/bin/env bash'}\n#{cloud_init_data}"
    user_data Cfer::Core::Fn::base64(data)
  end

end

require_relative 'provisioning/cfn-bootstrap.rb'
require_relative 'provisioning/chef.rb'

