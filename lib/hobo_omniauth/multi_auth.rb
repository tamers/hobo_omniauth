module HoboOmniauth

  # include this into your User class to get the "single authenticator" strategy.  See Readme
  module MultiAuth
    module ClassMethods
      def authorize(auth, current_user)
        authorization = Authorization.find_by_provider_and_uid(auth['provider'], auth['uid'])
        authorization ||= Authorization.find_by_email_address(auth['info']['email'])
        unless authorization
          info = auth.info.to_hash
          extra = auth.extra._?.raw_info
          info.reverse_merge!(extra.to_hash) unless extra.nil?
          info['email_address'] = info['email']
          info['provider'] = auth.provider
          info['uid'] = auth.uid

          if current_user.nil? || current_user.guest?
            current_user = self.find_by_email_address(auth['info']['email'])
          end
          if current_user.nil? || current_user.guest?
            Rails.logger.info "New user from #{info.to_json}"
            creator = self::Lifecycle.creators[:from_omniauth]
            if creator
              current_user = self::Lifecycle.from_omniauth(current_user, info.with_indifferent_access)
            else
              current_user = self.new
              current_user.attributes = info.slice(*accessible_attributes.to_a)
            end
            current_user.save!
          end

          info['user'] = current_user
          authorization = Authorization.new(info.slice(*Authorization.accessible_attributes.to_a))
          authorization.save!
        end

        authorization.user
      end
    end

    def self.included(base)
      base.has_many(:authorizations)
      base.extend(ClassMethods)
    end
  end
end
