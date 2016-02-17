require 'erubis'

module CferExt::Provisioning
BERKSFILE_TEMPLATE = <<-EOF.strip_heredoc
<% sources.each do |source| %>
source "<%= source %>
<% end %>

<% cookbooks.each do |cookbook| %>
  <% case cookbook
     when Hash %>
     <% cookbook.each do |k, v| %>
cookbook "<%= k %>", "<%= v.to_s %>"
     <%end %>
  <% when String %>
cookbook("<%= cookbook %>")
  <% end
end %>
EOF

  def install_chef(options = {})
    chef_config = options[:chef]

    setup_set = [ :install_chef ]
    run_set = [ :run_chef ]
    cfn_init_config :install_chef do
      command :install_chef, "curl https://www.opscode.com/chef/install.sh | bash -s -- -v #{options[:chef_version] || 'latest'}"
      command :make_ohai_hints, 'mkdir -p /etc/chef/ohai/hints && touch /etc/chef/ohai/hints/ec2.json'
      command :make_chefdir, 'mkdir -p /var/chef/cookbooks && mkdir -p /var/chef/data_bags'
    end

    if options[:berkshelf]
      cfn_init_config :install_berkshelf do
        command :install_berkshelf, '/opt/chef/embedded/bin/gem install berkshelf --no-ri --no-rdoc'
      end
      setup_set.append :install_berkshelf
    end

    cfn_init_config :run_chef do
      file "/etc/chef/config.json", content: chef_config.to_json,
        owner: 'root',
        group: 'root'
    end

    if options[:berkshelf]
      if options[:berkshelf][:sources].empty?
        options[:berkshelf][:sources] = [ "https://supermarket.chef.io" ]
      end
      cfn_init_config :run_berkshelf do
        file '/var/chef/Berksfile', content: Erubis::Eruby.new(BERKSFILE_TEMPLATE).result(options[:berkshelf])
        command :run_berkshelf, '/opt/chef/embedded/bin/berks update -b /var/chef/Berksfile && /opt/chef/embedded/bin/berks install -b /var/chef/Berksfile', env: { :BERKSHELF_PATH => '/var/chef' }
      end
      run_set.prepend :run_berkshelf
    end


    cfn_init_config_set :install_chef, setup_set
    cfn_init_config_set :run_chef, run_set
    cfn_init_config_set :default, [ { "ConfigSet" => :install_chef}, { "ConfigSet" => :run_chef }]

  end

  def chef_solo(options = {})
    raise "Chef already configured on this resource" if @chef
    @chef = true

    install_chef(options)

    cfn_init_config :run_chef do
      file "/etc/chef/solo.rb", content: options[:solo_rb] || Cfer::Core::Fn::join("\n", [
        "cookbook_path '/var/chef/cookbooks'",
        "log_location '/var/log/chef-client.log'"
      ]),
      owner: 'root',
      group: 'root'

      command :run_chef, 'chef-solo -c /etc/chef/solo.rb -j /etc/chef/config.json'
    end
  end
end

