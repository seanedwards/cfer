require 'yaml'


module CferExt::Provisioning

  class ChefSolo
    def initialize(options = {})
      @options = options
    end

    def apply(resource)
      resource.user_data Base64.encode64(case @options[:flavor]
        when :ubuntu
          apply_ubuntu(resource)
        end)
    end

    def encrypted_data_bag_secret(val)
      @encrypted_data_bag_secret = val
    end

    def attributes(val)
      @attributes = val
    end

    def run_list(runlist)
    end

    def github(url)
    end

    private
    def apply_ubuntu(resource)
      <<-EOS.strip_heredoc
        #!/usr/bin/env bash
        apt-get update --fix-missing
        apt-get install -y ruby2.0 ruby2.0-devel git build-essential
        gem install chef berkshelf
      EOS
    end
  end
end
