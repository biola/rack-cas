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

Coming Soon
===========
* __Single sign out__

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

Integration
===========
Your app should __return a [401 status](http://httpstatus.es/401)__ whenever a request is made that requires authentication. Rack-CAS will catch these responses and attempt to authenticate via your CAS server.

Once authentication with the CAS server has completed, Rack-CAS will set the following session variables:

    request.session['cas']['user'] #=> johndoe
    request.session['cas']['extra_attributes'] #=> { 'first_name' => 'John', 'last_name' => ... }

__NOTE:__ `extra_attributes` will be an empty hash unless they've been [configured on your CAS server](http://code.google.com/p/rubycas-server/wiki/HowToSendExtraUserAttributes).