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

    def validate_service(service_url, ticket)
      unless RackCAS.config.use_saml_validation?
        response = ServiceValidationResponse.new validate_service_url(service_url, ticket)
      else
        response = SAMLValidationResponse.new saml_validate_url(service_url), ticket
      end
      [response.user, response.extra_attributes]
    end

    protected

    def saml_validate_url(service_url)
      service_url = URL.parse(service_url).remove_param('ticket').to_s
      @url.dup.append_path('samlValidate').add_params(TARGET: service_url)
    end

    def validate_service_url(service_url, ticket)
      service_url = URL.parse(service_url).remove_param('ticket').to_s
      @url.dup.append_path('serviceValidate').add_params(service: service_url, ticket: ticket)
    end
  end
end
