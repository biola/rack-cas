Rack-CAS
========
Rack-CAS is simple [Rack](http://rack.github.com/) middleware to perform [CAS](http://jasig.org/cas) client authentication.

Features
========
* __Rack based__
* __Framework independent__  
Works with but doesn't depend on Rails, Sinatra, etc.
* __Minimal dependencies__  
Current gem dependencies are [rack](http://rubygems.org/gems/rack), [addressable](http://rubygems.org/gems/addressable) and [nokogiri](http://rubygems.org/gems/nokogiri).
* __Supports CAS extra attributes__  
Extra attributes are a mess though. So let me know if your brand of CAS server isn't supported.
* __Single sign out__  
One of the included session stores must be used.

Coming Soon
===========
* __Single sign out compatible session store for Active Record__

Requirements
============
* Ruby >= 1.9.2
* A working [CAS server](http://code.google.com/p/rubycas-server)

Installation
============

    gem install rack-cas

Or for [Bundler](http://gembundler.com):

    gem 'rack-cas'

Then in your `config.ru` file add

    require 'rack/cas'
    use Rack::CAS, server_url: 'https://login.example.com/cas'

Single Sign Out
---------------
Support for [single sign out](https://wiki.jasig.org/display/CASUM/Single+Sign+Out) requires the use of one of the included session stores listed below.

* Mongoid

To use the session store with Rails add the following to your `config/initializers/session_store.rb` file:

    require 'rack-cas/session_store/rails/mongoid'
    YourApp::Application.config.session_store :mongoid_store

For other Rack-compatible frameworks, add the following to your config.ru file:

    requre 'rack-cas/sessions_store/rack/mongoid'
    use Rack::Session::MongoidStore

Then tell the RackCAS where to find your sessions:

    require 'rack/cas'
    require 'rack-cas/session_store/mongoid'
    use Rack::CAS server_url: 'http://login.example.com/cas', session_store: RackCAS:MongoidStore

Integration
===========
Your app should __return a [401 status](http://httpstatus.es/401)__ whenever a request is made that requires authentication. Rack-CAS will catch these responses and attempt to authenticate via your CAS server.

Once authentication with the CAS server has completed, Rack-CAS will set the following session variables:

    request.session['cas']['user'] #=> johndoe
    request.session['cas']['extra_attributes'] #=> { 'first_name' => 'John', 'last_name' => ... }

__NOTE:__ `extra_attributes` will be an empty hash unless they've been [configured on your CAS server](http://code.google.com/p/rubycas-server/wiki/HowToSendExtraUserAttributes).

Testing
=======

Controller Tests
----------------
Testing your controllers and such should be as simple as setting the session variables manually in a helper.

    def set_current_user(user)
      session['cas'] = { 'user' => user.username, 'extra_attributes' => {} }
    end

Integration Tests
-----------------
Integration testing using something like [Capybara](http://jnicklas.github.com/capybara/) is a bit trickier because the session can't be manipulated directly. So for integration tests, I recommend using the provided `Rack::FakeCAS` middleware instead of `Rack::CAS`.

    require 'rack/fake_cas'
    use Rack::FakeCAS

Then you can simply do the following in your integration tests in order to log in.

    visit '/restricted_path'
    fill_in 'username', with: 'johndoe'
    fill_in 'password', with: 'any password'
    click_button 'Login'

__NOTE:__ The FakeCAS middleware will authenticate any username with any password and so should never be used in production.