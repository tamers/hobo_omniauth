$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "hobo_omniauth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "hobo_omniauth"
  s.version     = HoboOmniauth::VERSION
  s.authors     = ["Bryan Larsen"]
  s.email       = ["bryan@larsen.st"]
  s.homepage    = "http://hobocentral.net"
  s.summary     = "Hobo adapter for omniauth."

  s.test_files = Dir["test/**/*"]

  s.add_dependency "omniauth", "~> 1.1"
  # s.add_dependency "jquery-rails"

  s.files = `git ls-files -z`.split("\0")
  s.add_runtime_dependency('hobo')
end
