module HoboOmniauth

  # include this into your User controller
  module Controller
    module ClassMethods
    end

    def omniauth_callback
    # Try and find a user with matching authorization credentials
      if self.this = model.authorize(request.env["omniauth.auth"], current_user)
        self.send(:sign_user_in, self.this)
      else
        if !request.env["omniauth.auth"].nil?
          raise request.env["omniauth.auth"].to_yaml
        else
          raise request.env["message"].to_yaml
        end
      end
    end

    def included(base)
      base.extend(ClassMethods)
    end
  end
end
