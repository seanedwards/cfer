require 'yaml'

module Cfer
  module Cfn
    class CferCredentialsProvider < Aws::SharedCredentials
      private

      def load_from_path
        profile = load_profile
        credentials = Aws::Credentials.new(
          profile['aws_access_key_id'],
          profile['aws_secret_access_key'],
          profile['aws_session_token']
        )
        @credentials =
          if role_arn = profile['role_arn']
            role_creds =
              begin
                YAML::load_file('.cfer-role')
              rescue
                {}
              end

            if stored_creds = role_creds[profile_name]
              if (Time.now.to_i + 5 * 60) > stored_creds[:expiration].to_i
                stored_creds = nil
              end
            end

            if stored_creds == nil
              role_credentials_options = {
                role_session_name: [*('A'..'Z')].sample(16).join,
                role_arn: role_arn,
                credentials: credentials
              }

              if profile['mfa_serial']
                role_credentials_options[:serial_number] ||= profile['mfa_serial']
                role_credentials_options[:token_code] ||= HighLine.new($stdin, $stderr).ask('Enter MFA Code:')
              end

              creds = Aws::AssumeRoleCredentials.new(role_credentials_options)
              stored_creds = {
                expiration: creds.expiration,
                credentials: creds.credentials
              }
              role_creds[profile_name] = stored_creds
            end

            IO.write('.cfer-role', YAML.dump(role_creds))
            stored_creds[:credentials]
          else
            credentials
          end
      end

      def load_profile
        if profile = profiles[profile_name]
          # Add all options from source profile
          if source = profile.delete('source_profile')
            profiles[source].merge(profile)
          else
            profile
          end
        else
          msg = "Profile `#{profile_name}' not found in #{path}"
          raise Aws::Errors::NoSuchProfileError, msg
        end
      end
    end
  end
end
