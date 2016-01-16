require 'rack'
require 'rack-cas/cas_request'

class Rack::FakeCAS
  def initialize(app, config={}, attributes_config={})
    @app = app
    @config = config || {}
    @attributes_config = attributes_config || {}
  end

  def call(env)
    @request = Rack::Request.new(env)
    cas_request = CASRequest.new(@request)

    if cas_request.path_matches? @config[:exclude_paths] || @config[:exclude_path]
      return @app.call(env)
    end

    case @request.path_info
    when '/login'
      username = @request.params['username']
      @request.session['cas'] = {}
      @request.session['cas']['user'] = username
      @request.session['cas']['extra_attributes'] = @attributes_config.fetch(username, {})
      redirect_to @request.params['service']

    when '/logout'
      @request.session.send respond_to?(:destroy) ? :destroy : :clear
      redirect_to "#{@request.script_name}/"

    # built-in way to get to the login page without needing to return a 401 status
    when '/fake_cas_login'
      render_login_page

    else
      response = @app.call(env)

      if response[0] == 401 # access denied
        render_login_page
      else
        response
      end
    end
  end

  protected

  def render_login_page
    [ 200, { 'Content-Type' => 'text/html' }, [login_page] ]
  end

  def login_page
    <<-EOS
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8"/>
    <title>Fake CAS</title>
  </head>
  <body>
    <form action="#{@request.script_name}/login" method="post">
      <input type="hidden" name="service" value="#{@request.url}"/>
      <label for="username">Username</label>
      <input id="username" name="username" type="text"/>
      <label for="password">Password</label>
      <input id="password" name="password" type="password"/>
      <input type="submit" value="Login"/>
    </form>
  </body>
</html>
    EOS
  end

  def redirect_to(url)
    [ 302, { 'Content-Type' => 'text/plain', 'Location' => url }, ['Redirecting you...'] ]
  end
end
