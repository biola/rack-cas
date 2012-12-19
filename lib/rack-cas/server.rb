require 'rack-cas/url'
require 'rack-cas/service_validation_response'

module RackCAS
  class Server
    def initialize(url)
      @url = RackCAS::URL.parse(url)
    end

    def login_url(service_url)
      service_url = URL.parse(service_url).to_s
      @url.dup.append_path('login').add_params(service: service_url)
    end

    def logout_url
      @url.dup.append_path('logout')
    end

    def validate_service(service_url, ticket)
      response = ServiceValidationResponse.new validate_service_url(service_url, ticket)
      [response.user, response.extra_attributes]
    end

    protected

    def validate_service_url(service_url, ticket)
      service_url = URL.parse(service_url).remove_param('ticket').to_s
      @url.dup.append_path('serviceValidate').add_params(service: service_url, ticket: ticket)
    end
  end
end