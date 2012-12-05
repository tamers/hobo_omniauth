require 'omniauth'
require "hobo_omniauth/engine"
require "hobo_omniauth/user_auth"
require "hobo_omniauth/multi_auth"
require "hobo_omniauth/controller"

module HoboOmniauth

  @@root = Pathname.new File.expand_path('../..', __FILE__)
  def self.root; @@root; end

  EDIT_LINK_BASE = 'https://github.com/my_github_username/hobo_omniauth/edit/master'

  if defined?(Rails)
    require 'hobo_omniauth/railtie'

    class Engine < ::Rails::Engine
    end
  end
end
