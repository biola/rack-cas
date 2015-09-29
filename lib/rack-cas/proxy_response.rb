module RackCAS
  class ProxyResponse
    class ProxyFailure < StandardError; end
    class RequestInvalidError < ProxyFailure; end
    class UnauthorizedServiceError < ProxyFailure; end
    class InternalError < ProxyFailure; end

    REQUEST_HEADERS = { 'Accept' => '*/*' }

    def initialize(url)
      @url = URL.parse(url)
    end

    def proxy_ticket
      if success?
        xml.xpath('/cas:serviceResponse/cas:proxySuccess/cas:proxyTicket').text
      else
        case failure_code
        when 'INVALID_REQUEST'
          raise RequestInvalidError, failure_message
        when 'UNAUTHORIZED_SERVICE'
          raise UnauthorizedServiceError, failure_message
        when 'INTERNAL_ERROR'
          raise InternalError, failure_message
        else
          raise ProxyFailure, failure_message
        end
      end
    end

    protected

    def success?
      @success ||= !!xml.at('/cas:serviceResponse/cas:proxySuccess')
    end

    def proxy_failure
      @proxy_failure ||= xml.at('/cas:serviceResponse/cas:proxyFailure')
    end

    def failure_message
      if proxy_failure
        proxy_failure.text.strip
      end
    end

    def failure_code
      if proxy_failure
        proxy_failure['code']
      end
    end

    def response
      require 'net/http'
      return @response unless @response.nil?

      http = Net::HTTP.new(@url.host, @url.inferred_port)
      if @url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = RackCAS.config.verify_ssl_cert? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      end

      http.start do |conn|
        @response = conn.get(@url.request_uri, REQUEST_HEADERS)
      end

      @response
    end

    def xml
      return @xml unless @xml.nil?

      @xml = Nokogiri::XML(response.body)
    end

  end
end