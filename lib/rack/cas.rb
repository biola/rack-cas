require 'rack'
require 'addressable/uri'
require 'rack-cas/server'
require 'rack-cas/cas_request'

class Rack::CAS
  attr_accessor :server_url

  def initialize(app, config={})
    @app = app

    RackCAS.config.update config
  end

  def call(env)
    request = Rack::Request.new(env)
    cas_request = CASRequest.new(request)

    return @app.call(env) if exclude_request?(cas_request)

    if cas_request.ticket_validation?
      log env, 'rack-cas: Intercepting ticket validation request.'

      begin
        user, extra_attrs, pgt_iou = get_user(request.url, cas_request.ticket)
      rescue RackCAS::ServiceValidationResponse::TicketInvalidError, RackCAS::SAMLValidationResponse::TicketInvalidError
        log env, 'rack-cas: Invalid ticket. Redirecting to CAS login.'

        return redirect_to server.login_url(cas_request.service_url).to_s
      end

      store_session request, user, cas_request.ticket, extra_attrs, pgt_iou
      return redirect_to cas_request.service_url
    end

    if cas_request.pgt_callback?
      log env, 'rack-cas: Intercepting proxy granting ticket callback request.'
      RackCAS.config.session_store.create_proxy_granting_ticket(cas_request.pgt_iou, cas_request.pgt)
      return [200, {'Content-Type' => 'text/plain'}, ['CAS proxy granting ticket created successfully.']]
    end

    if cas_request.logout?
      log env, 'rack-cas: Intercepting logout request.'

      request.session.send (request.session.respond_to?(:destroy) ? :destroy : :clear)
      return redirect_to server.logout_url(request.params).to_s
    end

    if cas_request.single_sign_out? && RackCAS.config.session_store?
      log env, 'rack-cas: Intercepting single-sign-out request.'

      RackCAS.config.session_store.destroy_session_by_cas_ticket(cas_request.ticket)
      return [200, {'Content-Type' => 'text/plain'}, ['CAS Single-Sign-Out request intercepted.']]
    end

    response = @app.call(env)

    if response[0] == 401 && !ignore_intercept?(request) # access denied
      log env, 'rack-cas: Intercepting 401 access denied response. Redirecting to CAS login.'

      redirect_to server.login_url(request.url).to_s
    else
      response
    end
  end

  protected

  def server
    @server ||= RackCAS::Server.new(RackCAS.config.server_url)
  end

  def ignore_intercept?(request)
    return false if (validator = RackCAS.config.ignore_intercept_validator).nil?
    validator.call(request)
  end

  def exclude_request?(cas_request)
    if (validator = RackCAS.config.exclude_request_validator)
      validator.call(cas_request.request)
    else
      cas_request.path_matches? RackCAS.config.exclude_path || RackCAS.config.exclude_paths
    end
  end

  def get_user(service_url, ticket)
    server.validate_service(service_url, ticket, RackCAS.config.pgt_callback_url)
  end

  def store_session(request, user, ticket, extra_attrs = {}, pgt_iou = nil)
    if RackCAS.config.extra_attributes_filter?
      extra_attrs.select! { |key, val| RackCAS.config.extra_attributes_filter.map(&:to_s).include? key.to_s }
    end

    request.session['cas'] = { 'user' => user, 'ticket' => ticket, 'extra_attributes' => extra_attrs }

    if pgt_iou
      pgt = RackCAS.config.session_store.proxy_granting_ticket_for(pgt_iou)
      request.session['cas']['pgt'] = pgt if pgt
    end

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
