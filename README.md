Rack-CAS [![Build Status](https://travis-ci.org/biola/rack-cas.svg?branch=master)](https://travis-ci.org/biola/rack-cas) [![Gem Version](https://badge.fury.io/rb/rack-cas.svg)](https://badge.fury.io/rb/rack-cas)
========
Rack-CAS is simple [Rack](http://rack.github.com/) middleware to perform [CAS](http://en.wikipedia.org/wiki/Central_Authentication_Service) client authentication.

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
* Ruby >= 2.0
* A working [CAS server](http://casino.rbcas.com)
* An app that [returns a `401 Unauthorized`](#integration) status when authentication is required

Installation
============

Rails
-----

Add `gem 'rack-cas'` to your [`Gemfile`](http://gembundler.com/gemfile.html) and run `bundle install`

Once the necessary gems have been installed, in your `config/application.rb` add:
```ruby
config.rack_cas.server_url = 'https://cas.example.com/'
```
If the the server URL depends on your environment, you can define it in the according file: `config/environments/<env>.rb`

### Protocol

Since protocol `p3` the protocol is prepended in certain urls. If you wish to use protocol `p3` set the following config variable

`config.rack_cas.protocol = 'p3'`

[For more info](http://jasig.github.io/cas/4.1.x/protocol/CAS-Protocol-Specification.html#cas-uris)

### Single Logout ###

If you wish to enable [single logout](http://apereo.github.io/cas/4.0.x/installation/Logout-Single-Signout.html) you'll need to modify your configuration as below.

#### Active Record ####

Set the `session_store` in your `config/application.rb`:
```ruby
require 'rack-cas/session_store/active_record'
config.rack_cas.session_store = RackCAS::ActiveRecordStore
```
Edit your `config/initializers/session_store.rb` file with the following:
```ruby
require 'rack-cas/session_store/rails/active_record'
Rails.application.config.session_store ActionDispatch::Session::RackCasActiveRecordStore
```
Run:
```ruby
rails generate cas_session_store_migration
rake db:migrate
```
#### Mongoid ####

Set the `session_store` in your `config/application.rb`:
```ruby
require 'rack-cas/session_store/mongoid'
config.rack_cas.session_store = RackCAS::MongoidStore
```
Edit your `config/initializers/session_store.rb` file with the following:
```ruby
require 'rack-cas/session_store/rails/mongoid'
YourApp::Application.config.session_store ActionDispatch::Session::RackCasMongoidStore
```
#### Redis ####

Set the `session_store` in your `config/application.rb`:
```ruby
require 'rack-cas/session_store/redis'
config.rack_cas.session_store = RackCAS::RedisStore
```
Edit your `config/initializers/session_store.rb` file with the following:
```ruby
require 'rack-cas/session_store/rails/redis'
YourApp::Application.config.session_store ActionDispatch::Session::RackCasRedisStore
```
Optionally, Set the `redis_options` in your `config/application.rb`.
You can specify anything `Redis.new` allows.
For example:
```ruby
config.rack_cas.redis_options = {path: '/tmp/redis.sock',driver: :hiredis}
```
Sinatra and Other Rack-Compatible Frameworks
--------------------------------------------

Add `gem 'rack-cas'` to your [`Gemfile`](http://gembundler.com/gemfile.html) and run `bundle install`

Add the following to your `config.ru` file:
```ruby
require 'rack/cas'
use Rack::CAS, server_url: 'https://login.example.com/cas'
```
See the [example Sinatra app](https://gist.github.com/adamcrown/a7e757759469033584c4) to get started.

### Single Sign Out ###

You will need to store sessions in session store supported by Rack CAS.

#### Active Record ####
Add a migration that looks roughly like

    class AddSessionStore < ActiveRecord::Migration
    	def change
    		create_table :sessions do |t|
    			t.string :cas_ticket
    			t.string :session_id
    			t.text :data
    			t.datetime :created_at
    			t.datetime :updated_at
    		end
    	end
    end

Then use the middleware with

    require 'rack-cas/session-store/rack/active_record'
    use Rack::Session::RackCASActiveRecordStore

Configuration
=============

Extra Attributes
----------------

You can whitelist which extra attributes to keep.
In your `config/application.rb`:
```ruby
config.rack_cas.extra_attributes_filter = %w(some_attribute some_other_attribute)
```

Excluding Paths
---------------

If you have some parts of your app that should not be CAS authenticated (such as an API namespace), just pass `exclude_path` to the middleware. You can pass in a string that matches the beginning of the path, a regular expression or an array of strings and regular expressions.
```ruby
use Rack::CAS, server_url: '...', exclude_path: '/api'
use Rack::CAS, server_url: '...', exclude_path: /\.json/
use Rack::CAS, server_url: '...', exclude_paths: ['/api', /\.json/]
```
The same options can be passed to `FakeCAS`.
```ruby
use Rack::FakeCAS, exclude_path: '/api'
```

Excluding Requests
------------------

If the path exclusion is not suitable to ignore the CAS authentication in some parts of your app, you can pass
`exclude_request_validator` to the middleware with a custom validator. You need to pass a `Proc` object that will accept
a `Rack::Request` object as a parameter.

```ruby
use Rack::CAS, server_url: '...', exclude_request_validator: Proc.new { |req| req.env['HTTP_CONTENT_TYPE'] == 'application/json' }
```

Service URL
--------------------

Sometimes you need to force the `service=` attribute on login requests, and not just use the request url in an automatic way.

```ruby
use Rack::CAS, service: 'http://anotherexample.com'
```

Ignore 401 Intercept
--------------------

For some requests you might want to ignore the 401 intercept made by the middleware. For example when we want CAS to
authenticate API requests but leave the redirect handling to the client. For this you can use the
`ignore_intercept_validator`. You need to pass a `Proc` object that will accept a `Rack::Request` object as a parameter.

```ruby
use Rack::CAS, server_url: '...', ignore_intercept_validator: Proc.new { |req| req.env['HTTP_CONTENT_TYPE'] == 'application/json' }
use Rack::CAS, server_url: '...', ignore_intercept_validator: Proc.new { |req| req.env['PATH_INFO'] =~ 'api' }
```

SSL Cert Verification
---------------------

If you're working in development or staging your CAS server may not have a legit SSL cert. You can turn off SSL Cert verification by adding the following to `config/application.rb`.

```ruby
config.rack_cas.verify_ssl_cert = false
```

CAS Login Renew Flag
--------------

The CAS standard allows for a `renew=true` parameter to be passed to the CAS server which will force the user to re-login every time CAS authentication is performed, for added security. To enable this for your application, add the following to `config/application.rb`.

```ruby
config.rack_cas.renew = true
```

Integration
===========
Your app should __return a [401 status](http://httpstatus.es/401)__ whenever a request is made that requires authentication. Rack-CAS will catch these responses and attempt to authenticate via your CAS server.

Once authentication with the CAS server has completed, Rack-CAS will set the following session variables:
```ruby
request.session['cas']['user'] #=> johndoe
request.session['cas']['extra_attributes'] #=> { 'first_name' => 'John', 'last_name' => ... }
```
__NOTE:__ `extra_attributes` will be an empty hash unless they've been [configured on your CAS server](http://casino.rbcas.com/docs/configuration/#ldap).

Testing
=======

Controller Tests
----------------
Testing your controllers and such should be as simple as setting the session variables manually in a helper.
```ruby
def set_current_user(user)
  session['cas'] = { 'user' => user.username, 'extra_attributes' => {} }
end
```
Integration Tests
-----------------
Integration testing using something like [Capybara](http://jnicklas.github.com/capybara/) is a bit trickier because the session can't be manipulated directly. So for integration tests, I recommend using the provided `Rack::FakeCAS` middleware instead of `Rack::CAS`.
```ruby
require 'rack/fake_cas'
use Rack::FakeCAS
```
In addition you can pass a Hash to configure extra attributes for predefined
usernames.
```ruby
use Rack::FakeCAS, {}, {'john' => {'name' => 'John Doe'}}
```
If you are using Rails, FakeCAS is automatically used in the test environment by default. If you would like to activate it in any other environment, add the following to the corresponding `config/environments/<env>.rb`:
```ruby
config.rack_cas.fake = true
```
You can also configure extra attribute mappings through the Rails config:
```ruby
config.rack_cas.fake_attributes = { 'john' => { 'name' => 'John Doe' } }
```
Then you can simply do the following in your integration tests in order to log in.
```ruby
visit '/restricted_path'
fill_in 'username', with: 'johndoe'
fill_in 'password', with: 'any password'
click_button 'Login'
```
__NOTE:__ The FakeCAS middleware will authenticate any username with any password and so should never be used in production.
