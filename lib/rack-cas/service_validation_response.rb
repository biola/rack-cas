require 'yaml'

module RackCAS
  class ServiceValidationResponse
    class AuthenticationFailure < StandardError; end
    class RequestInvalidError < AuthenticationFailure; end
    class TicketInvalidError < AuthenticationFailure; end
    class ServiceInvalidError < AuthenticationFailure; end

    REQUEST_HEADERS = { 'Accept' => '*/*' }

    def initialize(url)
      @url = URL.parse(url)
    end

    def user
      if success?
        xml.xpath('/cas:serviceResponse/cas:authenticationSuccess/cas:user').text
      else
        case failure_code
        when 'INVALID_REQUEST'
          raise RequestInvalidError, failure_message
        when 'INVALID_TICKET'
          raise TicketInvalidError, failure_message
        when 'INVALID_SERVICE'
          raise ServiceInvalidError, failure_message
        else
          raise AuthenticationFailure, failure_message
        end
      end
    end

    def extra_attributes
      attrs = {}

      raise AuthenticationFailure, failure_message unless success?

      # Jasig style
      if attr_node = xml.at('/cas:serviceResponse/cas:authenticationSuccess/cas:attributes')
        attr_node.children.each do |node|
          if node.is_a? Nokogiri::XML::Element
            attrs[node.name] = parse_extra_attribute(node.text)
          end
        end

      # RubyCas-Server style
      else
        xml.at('/cas:serviceResponse/cas:authenticationSuccess').children.each do |node|
          if node.is_a? Nokogiri::XML::Element
            if !node.namespace || !node.namespace.prefix == 'cas'
              attrs[node.name] = parse_extra_attribute(node.text)
            end
          end
        end
      end

      attrs
    end

    protected

    def _parse_yaml(string)
      YAML.load(string)
    rescue
      nil
    end

    def parse_extra_attribute(string)
      parsed = _parse_yaml(string.strip) || string
      # Because YAML is a loose format it will accept most strings.
      # Most of the time, we don't want to muck with the string.
      # We probably do if the YAML parsing outputs a non-string.
      parsed = string if parsed.kind_of? String
      parsed
    end

    def success?
      @success ||= !!xml.at('/cas:serviceResponse/cas:authenticationSuccess')
    end

    def authentication_failure
      @authentication_failure ||= xml.at('/cas:serviceResponse/cas:authenticationFailure')
    end

    def failure_message
      if authentication_failure
        authentication_failure.text.strip
      end
    end

    def failure_code
      if authentication_failure
        authentication_failure['code']
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
