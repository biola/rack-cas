require 'rack'
require 'addressable/uri'
require 'rack-cas/server'
require 'rack-cas/cas_request'

class Rack::CAS
  attr_accessor :server_url

  def initialize(app, config={})
    @app = app
    @server_url = config.delete(:server_url)
    @session_store = config.delete(:session_store)
    @config = config || {}

    raise ArgumentError, 'server_url is required' if @server_url.nil?
    if @session_store && !@session_store.respond_to?(:destroy_session_by_cas_ticket)
      raise ArgumentError, 'session_store does not support single-sign-out'
    end
  end

  def call(env)
    request = Rack::Request.new(env)
    cas_request = CASRequest.new(request)

    if cas_request.path_matches? @config[:exclude_paths] || @config[:exclude_path]
      return @app.call(env) 
    end

    if cas_request.ticket_validation?
      log env, 'rack-cas: Intercepting ticket validation request.'

      user, extra_attrs = get_user(request.url, cas_request.ticket)

      store_session request, user, cas_request.ticket, extra_attrs
      return redirect_to cas_request.service_url
    end

    if cas_request.logout?
      log env, 'rack-cas: Intercepting logout request.'

      request.session.clear
      return redirect_to server.logout_url(request.params).to_s
    end

    if cas_request.single_sign_out? && @session_store
      log env, 'rack-cas: Intercepting single-sign-out request.'

      @session_store.destroy_session_by_cas_ticket(cas_request.ticket)
      return [200, {'Content-Type' => 'text/plain'}, ['CAS Single-Sign-Out request intercepted.']]
    end

    response = @app.call(env)

    if response[0] == 401 # access denied
      log env, 'rack-cas: Intercepting 401 access denied response. Redirecting to CAS login.'

      redirect_to server.login_url(request.url).to_s
    else
      response
    end
  end

  protected

  def server
    @server ||= RackCAS::Server.new(@server_url)
  end

  def get_user(service_url, ticket)
    server.validate_service(service_url, ticket)
  end

  def store_session(request, user, ticket, extra_attrs = {})
    request.session['cas'] = { 'user' => user, 'ticket' => ticket, 'extra_attributes' => extra_attrs }
  end

  def redirect_to(url, status=302)
    [ status, { 'Location' => url, 'Content-Type' => 'text/plain' }, ["Redirecting you to #{url}"] ]
  end

  def log(env, message, level = :info)
    if env['rack.logger']
      env['rack.logger'].send(level, message)
    else
      env['rack.errors'].write(message)
    end
  end
end