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
            role_credentials_options = {
              role_session_name: [*('A'..'Z')].sample(16).join,
              role_arn: role_arn,
              credentials: credentials
            }

            if profile['mfa_serial']
              role_credentials_options[:serial_number] ||= profile['mfa_serial']
              role_credentials_options[:token_code] ||= HighLine.new($stdin, $stderr).ask('Enter MFA Code:')
            end

            Aws::AssumeRoleCredentials.new(role_credentials_options).credentials
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
          raise Errors::NoSuchProfileError, msg
        end
      end
    end
  end
end
