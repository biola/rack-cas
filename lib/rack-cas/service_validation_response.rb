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
            if attrs.has_key?(node.name)
              attrs[node.name] = [attrs[node.name]] if attrs[node.name].is_a? String
              attrs[node.name] << node.text
            else
              attrs[node.name] = node.text
            end
          end
        end

      # RubyCas-Server style
      else
        xml.at('/cas:serviceResponse/cas:authenticationSuccess').children.each do |node|
          if node.is_a? Nokogiri::XML::Element
            if !node.namespace || !node.namespace.prefix == 'cas'
              # TODO: support JSON encoding
              attrs[node.name] = YAML.load node.text.strip
            else
              attrs['cas'] = [] unless attrs['cas']
              attrs['cas'] << { node.name => YAML.load(node.text.strip) }
            end
          end
        end
      end

      attrs
    end

    protected

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
