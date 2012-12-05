This is a plugin for [Hobo](http://hobocentral.net) that adds support for [omniauth](https://github.com/intridea/omniauth).   This allows you to support logins from Twitter, Facebook, Github, Google and many others.

### Installation

It can be installed into a Hobo app by typing:

    hobo generate install_plugin hobo_omniauth git://github.com/Hobo/hobo_omniauth.git

Then add `include HoboOmniauth::Controller` to app/controllers/users_controller.rb and either `include HoboOmniauth::UserAuth` or `include HoboOmniauth::MultiAuth` to app/models/user.rb.   Use `include HoboOmniauth::UserAuth` if you want to use only a single provider.  Use `include HoboOmniauth::MultiAuth` if you want to use multiple providers and/or allow the user to sign in with a password.  See *Strategies* below for more information on these two options.

Next create a migration to add the necessary tables & columns:

    rails generate hobo:migration

You will then need to add at least one provider.

### Providers

#### Github

[Register your application on Github](https://github.com/settings/applications/new).  If your Main URL is http://example.com/ then your Callback URL would be http://example.com/auth/github/callback

Github will supply you with a Client ID and a Client Secret.  Put those in environment variables named GITHUB_KEY and GITHUB_SECRET.  On a Unix this could be done with:

    $ export GITHUB_KEY=...
    $ export GITHUB_SECRET=...

Add to your Gemfile and run bundle:

    gem 'omniauth-github'

Create config/initializers/omniauth.rb:

    Rails.application.config.middleware.use OmniAuth::Builder do
       provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], :client_options => {:ssl => {:ca_path => "/etc/ssl/certs"}}
    end

(The :client_options specified are for Ubuntu.  Your OS may be different or may not need this option.)

#### Twitter

[Register your application on Twitter](https://dev.twitter.com/apps/new).  If your Website is set to http://example.com/ then your Callback URL would be http://example.com/auth/twitter/callback

Twitter will supply you with a Consumer key and a Consumer secret.  Put those in environment variables named TWITTER_KEY and TWITTER_SECRET.  On a Unix this could be done with:

    $ export TWITTER_KEY=...
    $ export TWITTER_SECRET=...

Add to your Gemfile and run bundle:

    gem 'omniauth-twitter'

Create config/initializers/omniauth.rb:

    Rails.application.config.middleware.use OmniAuth::Builder do
       provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET'], :client_options => {:ssl => {:ca_path => "/etc/ssl/certs"}}
    end

(The :client_options specified are for Ubuntu.  Your OS may be different or may not need this option.)

#### Others

Most omniauth providers work similarly to Twitter & Github.  If you use another provider, please help to update this documentation!

### Stategies

#### UserAuth

This is the simplest strategy.  Use it if you want all of your users to always sign in via the specified provider.

To use, you can add to any view:

     <login provider="github"/>

When the user clicks on the link, they will be signed in.  If the user does not exist, a new one will automatically be created.

You probably also want to add something like this to your application.dryml:

    <extend tag="account-nav">
      <old-account-nav merge without-sign-up>
        <log-in:><login provider="github"/></log-in:>
      </old-account-nav>
    </extend>

You may use more than one provider, but if a user signs in with two different providers, two different user accounts will be created; they will not be associated.   If your user model doesn't allow duplicate names or email addresses, you may get errors instead.

#### MultiAuth

This strategy allows a user to sign in with multiple providers and/or with the standard Hobo username/password pair.

To use, you can add to any view:

     <login provider="github"/>

If nobody is signed in when the link is clicked, the user has never previously authorized the provider, and no user exists at the email address that the provider returns, a new user and authorization is created and signed in.

If nobody is signed in when the link is clicked, the user has never previously authorized the provider, but a user and/or authorization exists for the email address that the provider returns, a new authorization is created for the user with that email address, and the user is signed in.

If nobody is signed in when the link is clicked and the user has been previously authorized, the user is signed in.

If a user is signed in when the link is clicked and the user has never previously authorized the provider, a new authorization for that user is created.

If a user is signed in when the link is clicked and the user has previously authorized the provider, nothing happens.

If a user is signed in when the link is clicked but has authorized the provider with a different account, the user is signed into the other account.

Note that some providers such as Twitter never return an email address.

Obviously, you're going to have to manage this complication for the user.   There are several different approaches.  Here's one; there are others:

    <def tag="login-or-signup">
      <if test="&logged_in?">
        <login provider="github">Log in via Github</login>
        <login provider="github">Sign up via Github</login>
        <a href="&signup_path">Sign up with a password</a>
      </if>
      <else>
        <unless test="&current_user.authorizations.find_by_provider('github')">
           <login provider="github">Associate account with Github</login>
        </unless>
        <a href="&logout_path">Log Out</a>
      </else>
    </def>

### Model Notes

Omniauth returns the user data described here:  https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema .  HoboOmniauth uses this when creating users and authorizations.

#### Users

If you have any fields with the same names as any of those passed in `info` or `extra_info`, and you have added these fields to attr_accessible, they will be populated on your user object when it is created by HoboOmniauth.

HoboOmniauth makes `email` also available as `email_address`, since the latter is the Hobo default.

In the following example, HoboOmniauth will create users with name, email_address and image url populated.   Not all providers will return an email address or image url.  If not, these will be NULL.

    fields do
      name          :string, :required
      email_address :email_address, :login => true, :validate => false
      image         :string
      administrator :boolean, :default => false
      timestamps
    end
    attr_accessible :name, :email_address, :image

Note that you will want to add `:validate => false` to `email_address` if you are using Twitter since Twitter does not return an email address.

The `:unique` constraint was removed from `name` since there is no guarantee that our providers will provide unique names.

Also note that users are created via User.new unless there's a :from_omniauth lifecycle action available and you're using MultiAuth.  The default Hobo user lifecycle has a default state of :inactive, so you must accommodate this somehow.   You could just change the default state to :active.   If you're using the UserAuth strategy, it's probably best just to completely delete the lifecycle.  Make sure to run `rails g hobo:migration` after deleting a lifecycle so the lifecycle state column gets removed.

With MultiAuth, you're probably best off adding a :from_omniauth lifecycle creator, such as this:

    lifecycle do
      ...
      create :from_omniauth, :params => [:name, :email_address], :become => :active
      ...
    end

If a :from_omniauth lifecycle creator is used, the :params list is used instead of attr_accessible list to determine valid attributes.

#### Authorizations

If you are using the AuthUser strategy, authorizations are not created.

Authorizations are declared with these fields

    fields do
      provider :string, :null => false, :index => true
      uid      :string, :null => false, :index => true, :unique => true
      email_address :string, :index => true
      name     :string
      nickname :string
      location :string
      image    :string
      description :text
      phone    :string
      urls     :serialized
      timestamps
    end
    attr_accessible :uid, :provider, :user, :user_id, :email_address, :name, :nickname, :location, :image, :description, :phone, :urls

### License

See MIT-LICENSE

