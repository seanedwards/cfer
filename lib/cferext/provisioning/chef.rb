require 'erubis'

module CferExt::Provisioning

  def install_chef(options = {})
    setup_set = [ :install_chef ]
    run_set = [ :run_chef ]
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
      run_set.prepend :run_berkshelf
    end

    cfn_init_config_set :install_chef, setup_set
    cfn_init_config_set :run_chef, run_set

  end

  def chef_solo(options = {})
    raise "Chef already configured on this resource" if @chef
    @chef = true

    chef_config = options[:node] || raise('`node` required when setting up chef')

    install_chef(options)

    cfn_init_config :run_chef do
      file "/etc/chef/solo.rb", content: options[:solo_rb] || Cfer::Core::Fn::join("\n", [
          "cookbook_path '/var/chef/cookbooks'",
          "log_location '/var/log/chef-client.log'"
        ]),
        owner: 'root',
        group: 'root'

      file "/etc/chef/config.json", content: chef_config.to_json,
        owner: 'root',
        group: 'root'

      chef_cmd = 'chef-solo -c /etc/chef/solo.rb -j /etc/chef/config.json'
      chef_cmd << " -o '#{options[:run_list].join(',')}'" if options[:run_list]
      command :run_chef, chef_cmd
    end
  end
end

