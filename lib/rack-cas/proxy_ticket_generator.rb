require 'rack-cas/url'
require 'rack-cas/proxy_response'

module RackCAS
  class ProxyTicketGenerator

    def self.generate(service_url, pgt)
      response = ProxyResponse.new proxy_url(service_url, pgt) 
      response.proxy_ticket
    end

    private

    def self.proxy_url(service_url, pgt)
      service_url = URL.parse(service_url).remove_param('ticket').to_s
      server_url = RackCAS::URL.parse(RackCAS.config.server_url)
      server_url.dup.tap do |url|
        url.append_path('proxy')
        url.add_params(targetService: service_url, pgt: pgt)
      end
    end

  end
end