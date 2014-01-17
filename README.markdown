Rack-CAS [![Build Status](https://travis-ci.org/biola/rack-cas.png?branch=master)](https://travis-ci.org/biola/rack-cas)
========
Rack-CAS is simple [Rack](http://rack.github.com/) middleware to perform [CAS](http://jasig.org/cas) client authentication.

Features
========
* __Rack based__
* __Framework independent__
Works with, but doesn't depend on Rails, Sinatra, etc.
* __Minimal dependencies__
Current gem dependencies are [rack](http://rubygems.org/gems/rack), [addressable](http://rubygems.org/gems/addressable) and [nokogiri](http://rubygems.org/gems/nokogiri).
* __Supports CAS extra attributes__
Extra attributes are a mess though. So let me know if your brand of CAS server isn't supported.
* __Single sign out__
One of the included session stores must be used.
* __Rake tasks to prune stale sessions__
`rack_cas:sessions:prune:active_record` and `rack_cas:sessions:prune:mongoid`

Requirements
============
* Ruby >= 1.9.2
* A working [CAS server](http://rubycas.github.com)
* An app that [returns a `401 Unauthorized`](#integration) status when authentication is requried

Installation
============

Rails
-----

Add `gem 'rack-cas'` to your [`Gemfile`](http://gembundler.com/gemfile.html) and run `bundle install`

Once the necessary gems have been installed, in your `config/application.rb` add:

    config.rack_cas.server_url = 'https://cas.example.com/'

If the the server URL depends on your environment, you can define it in the according file: `config/environments/<env>.rb`

### Single Sign Out ###

If you wish to enable [single sign out](https://wiki.jasig.org/display/CASUM/Single+Sign+Out) you'll need to modify your configuration as below.

#### Active Record ####

Set the `session_store` in your `config/application.rb`:

    require 'rack-cas/session_store/active_record'
    config.rack_cas.session_store = RackCAS::ActiveRecordStore

Edit your `config/initializers/session_store.rb` file with the following:

    require 'rack-cas/session_store/rails/active_record'
    YourApp::Application.config.session_store :rack_cas_active_record_store

Run:

    rails generate cas_session_store_migration
    rake db:migrate

#### Mongoid ####

Set the `session_store` in your `config/application.rb`:

    require 'rack-cas/session_store/mongoid'
    config.rack_cas.session_store = RackCAS::MongoidStore

Edit your `config/initializers/session_store.rb` file with the following:

    require 'rack-cas/session_store/rails/mongoid'
    YourApp::Application.config.session_store :rack_cas_mongoid_store

Sinatra and Other Rack-Compatible Frameworks
--------------------------------------------

Add `gem 'rack-cas'` to your [`Gemfile`](http://gembundler.com/gemfile.html) and run `bundle install`

Add the following to your `config.ru` file:

    require 'rack/cas'
    use Rack::CAS, server_url: 'https://login.example.com/cas'

### Single Sign Out ###

Single sign out support outside of Rails is currently untested. We'll be adding instructions here soon.

Configuration
=============

Excluding Paths
---------------

If you have some parts of your app that should not be CAS authenticated (such as an API namespace), just pass `exclude_path` to the middleware. You can pass in a string that matches the beginning of the path, a regular expression or an array of strings and regular expressions.

    use Rack::CAS, server_url: '...', exclude_path: '/api'
    use Rack::CAS, server_url: '...', exclude_path: /\.json/
    use Rack::CAS, server_url: '...', exclude_paths: ['/api', /\.json/]

The same options can be passed to `FakeCAS`.

    use Rack::FakeCAS, exclude_path: '/api'

Integration
===========
Your app should __return a [401 status](http://httpstatus.es/401)__ whenever a request is made that requires authentication. Rack-CAS will catch these responses and attempt to authenticate via your CAS server.

Once authentication with the CAS server has completed, Rack-CAS will set the following session variables:

    request.session['cas']['user'] #=> johndoe
    request.session['cas']['extra_attributes'] #=> { 'first_name' => 'John', 'last_name' => ... }

__NOTE:__ `extra_attributes` will be an empty hash unless they've been [configured on your CAS server](https://github.com/rubycas/rubycas-server/wiki/Extra-user-attributes).

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

In addition you can pass a Hash to configure extra attributes for predefined
usernames.

    use Rack::FakeCAS, {}, {'john' => {'name' => 'John Doe'}}

If you are using Rails, FakeCAS is automatically used in the test environment by default. If you would like to activate it in any other environment, add the following to the corresponding `config/environments/<env>.rb`:

    config.rack_cas.fake = true

You can also configure extra attribute mappings through the Rails config:

    config.rack_cas.fake_attributes = { 'john' => { 'name' => 'John Doe' } }

Then you can simply do the following in your integration tests in order to log in.

    visit '/restricted_path'
    fill_in 'username', with: 'johndoe'
    fill_in 'password', with: 'any password'
    click_button 'Login'

__NOTE:__ The FakeCAS middleware will authenticate any username with any password and so should never be used in production.
