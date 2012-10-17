require 'rack'

class Rack::FakeCAS
  def initialize(app, config={})
    @app = app
    @config = config
  end

  def call(env)
    @request = Rack::Request.new(env)
    
    case @request.path_info
    when '/login'
      @request.session['cas'] = {}
      @request.session['cas']['user'] = @request.params['username']
      @request.session['cas']['extra_attributes'] = {}
      redirect_to @request.params['service']

    when '/logout'
      @request.session.clear
      redirect_to "#{@request.script_name}/"

    else
      response = @app.call(env)

      if response[0] == 401 # access denied
        [ 200, { 'Content-Type' => 'text/html' }, [login_page] ]
      else
        response
      end
    end
  end

  protected

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