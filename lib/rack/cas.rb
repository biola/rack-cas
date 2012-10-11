require 'rack'
require 'addressable/uri'
require 'rack-cas/server'

class Rack::CAS
  attr_accessor :server_url

  def initialize(app, config={})
    @app = app
    @server_url = config.delete(:server_url)
    @config = config

    raise ArgumentError, 'server_url is required' if @server_url.nil?
  end

  def call(env)
    request = Rack::Request.new(env)

    if ticket_validation_request?(request)
      user, extra_attrs = get_user(request)

      store_session request, user, extra_attrs
      return redirect_to ticketless_url(request)
    end

    if logout_request?(request)
      request.session.clear
      return redirect_to server.logout_url.to_s
    end

    response = @app.call(env)

    if access_denied_response?(response)
      redirect_to server.login_url(request.url).to_s
    else
      response
    end
  end

  protected

  def server
    @server ||= RackCAS::Server.new(@server_url)
  end

  def logout_request?(request)
    request.path_info == '/logout'
  end

  def ticket_validation_request?(request)
    !get_ticket(request).nil?
  end

  def access_denied_response?(response)
    response[0] == 401
  end

  def ticketless_url(request)
    RackCAS::URL.parse(request.url).remove_param('ticket').to_s
  end

  def get_ticket(request)
    request.params['ticket']
  end

  def get_user(request)
    server.validate_service(request.url, get_ticket(request))
  end

  def store_session(request, user, extra_attrs = {})
    request.session['cas'] = {}
    request.session['cas']['user'] = user
    request.session['cas']['extra_attributes'] = extra_attrs
  end

  def redirect_to(url, status=302)
    [ status, { 'Location' => url, 'Content-Type' => 'text/plain' }, ["Redirecting you to #{url}"] ]
  end
end