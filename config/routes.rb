Rails.application.routes.draw do
  @controller = ApplicationController.subclasses.find{|c| c.ancestors.include?(HoboOmniauth::Controller)}
  if @controller
    get '/auth/:provider/callback' => "#{@controller.controller_name}#omniauth_callback"
    get '/auth/failure' => "#{@controller.controller_name}#omniauth_callback"
  end
end
