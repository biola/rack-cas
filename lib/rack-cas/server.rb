require 'rack-cas/url'
require 'rack-cas/saml_validation_response'
require 'rack-cas/service_validation_response'

module RackCAS
  class Server
    def initialize(url)
      @url = RackCAS::URL.parse(url)
    end

    def login_url(service_url, params = {})
      service_url = URL.parse(service_url).to_s
      base_params = {service: service_url}
      base_params[:renew] = true if RackCAS.config.renew?

      @url.dup.append_path('login').add_params(base_params.merge(params))
    end

    def logout_url(params = {})
      @url.dup.tap do |url|
        url.append_path('logout')
        url.add_params(params) unless params.empty?
      end
    end

    def validate_service(service_url, ticket, pgt_url = RackCAS.config.pgt_callback_url)
      pgt_iou = nil
      unless RackCAS.config.use_saml_validation?
        response = ServiceValidationResponse.new validate_service_url(service_url, ticket, pgt_url)
        if !!pgt_url
          pgt_iou = response.proxy_granting_ticket_iou
        end
      else
        response = SAMLValidationResponse.new saml_validate_url(service_url), ticket
      end
      [response.user, response.extra_attributes, pgt_iou]
    end

    protected

    def saml_validate_url(service_url)
      service_url = URL.parse(service_url).remove_param('ticket').to_s
      @url.dup.append_path(path_for_protocol('samlValidate')).add_params(TARGET: service_url)
    end

    def validate_service_url(service_url, ticket, pgt_url = RackCAS.config.pgt_callback_url)
      service_url = URL.parse(service_url).remove_param('ticket').to_s
      @url.dup.tap do |url|
        if ticket =~ /\AST\-[^\s]{1,253}\Z/
          url.append_path(path_for_protocol('serviceValidate'))
        else
          url.append_path(path_for_protocol('proxyValidate'))
        end
        url.add_params(service: service_url, ticket: ticket)
        url.add_params(pgtUrl: pgt_url) if pgt_url
      end
    end

    def path_for_protocol(path)
      if RackCAS.config.protocol && RackCAS.config.protocol == "p3"
        "p3/#{path}"
      else
        path
      end
    end

  end
end
