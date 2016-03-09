require 'erubis'

module CferExt::Provisioning

  def install_chef(options = {})
    setup_set = [ :install_chef ]
    cfn_init_config :install_chef do
      command :install_chef, "curl https://www.opscode.com/chef/install.sh | bash -s -- -v #{options[:version] || 'latest'}"
      command :make_ohai_hints, 'mkdir -p /etc/chef/ohai/hints && touch /etc/chef/ohai/hints/ec2.json'
      command :make_chefdir, 'mkdir -p /var/chef/cookbooks && mkdir -p /var/chef/data_bags'
    end

    if options[:berksfile]
      cfn_init_config :install_berkshelf do
        file '/var/chef/berkshelf.sh', content: <<-EOF.strip_heredoc
          export BERKSHELF_PATH=/var/chef/berkshelf

          # Some cookbooks have UTF-8, and cfn-init uses US-ASCII because of reasons
          export LANG=en_US.UTF-8
          export RUBYOPTS="-E utf-8"

          # Berkshelf seems a bit unreliable, so retry these commands a couple times.
          if [ -e Berksfile.lock ]
          then
            for i in {1..3}; do /opt/chef/embedded/bin/berks update && break || sleep 15; done
          fi
          for i in {1..3}; do /opt/chef/embedded/bin/berks vendor /var/chef/cookbooks -b /var/chef/Berksfile && break || sleep 15; done
        EOF
        command :install_berkshelf, '/opt/chef/embedded/bin/gem install berkshelf --no-ri --no-rdoc'
        command :install_git, 'apt-get install -y git'
      end
      setup_set.append :install_berkshelf
    end

    if options[:berksfile]
      cfn_init_config :run_berkshelf do
        file '/var/chef/Berksfile', content: options[:berksfile].strip_heredoc
        command :run_berkshelf, 'bash -l /var/chef/berkshelf.sh', cwd: '/var/chef'
      end
    end

    cfn_init_config_set :install_chef, setup_set
  end

  def set_chef_json(json = {})
    self[:Metadata]['CferExt::Provisioning::Chef'] = json || {}
  end

  def build_write_json_cmd(chef_solo_json_path)
    Cfer::Core::Fn.join('', [
      "mkdir -p #{File.dirname(chef_solo_json_path)} && cfn-get-metadata --region ",
        Cfer::Cfn::AWS.region,
        ' -s ', Cfer::Cfn::AWS.stack_name, ' -r ', @name,
        " | python -c 'import sys; import json; print " \
          "json.dumps(json.loads(sys.stdin.read()).get(" \
          '"CferExt::Provisioning::Chef",  {}), sort_keys=True, indent=2)',
        "' > #{chef_solo_json_path}"
    ])
  end

  def chef_solo(options = {})
    raise "Chef already configured on this resource" if @chef
    @chef = true

    chef_solo_config_path = options[:config_path] || '/etc/chef/solo.rb'
    chef_solo_json_path = options[:json_path] || '/etc/chef/config.json'

    chef_cookbook_path = options[:cookbook_path] || '/var/chef/cookbooks'
    chef_log_path = options[:log_path] || '/var/log/chef-client.log'

    install_chef(options) unless options[:no_install]

    set_chef_json(options[:json])
    write_json_cmd = build_write_json_cmd(chef_solo_json_path)

    cfn_init_config :write_chef_json do
      command :write_chef_json, write_json_cmd
    end

    cfn_init_config :run_chef do
      file chef_solo_config_path, content: options[:solo_rb] || Cfer::Core::Fn.join("\n", [
          "cookbook_path '#{chef_cookbook_path}'",
          "log_location '#{chef_log_path}'",
          ""
        ]),
        owner: 'root',
        group: 'root'

      chef_cmd = "chef-solo -c '#{chef_solo_config_path}' -j '#{chef_solo_json_path}'"
      chef_cmd << " -o '#{options[:run_list].join(',')}'" if options[:run_list]

      command :run_chef, chef_cmd
    end

    run_set = [ :write_chef_json, :run_chef ]
    run_set.prepend :run_berkshelf if options[:berkshelf]
    cfn_init_config_set :run_chef, run_set
  end
end

