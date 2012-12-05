module HoboOmniauth

  # include this into your User class to get the "single authenticator" strategy.  See Readme
  module UserAuth
    module ClassMethods
      def authorize(auth, current_user)
        user = self.find_or_create_by_uid(auth['uid'])
        if user.new_record?
          info = auth.info.to_hash
          extra = auth.extra._?.raw_info
          info.reverse_merge!(extra.to_hash) unless extra.nil?
          info['email_address'] = info['email']
          Rails.logger.info "New authorization from #{info.to_json}"
          user.attributes = info.slice(*accessible_attributes.to_a)
          user.save!
        end
        user
      end
    end

    def self.included(base)
      base.fields do
        uid :string, :required => true, :unique => true, :index => true, :null => false
      end
      base.extend(ClassMethods)
    end
  end
end
