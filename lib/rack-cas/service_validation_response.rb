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
        xml.at('//serviceResponse/authenticationSuccess/user').text
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
      if attr_node = xml.at('//serviceResponse/authenticationSuccess/attributes')
        attrs = parse_user_info(attr_node)

      # RubyCas-Server style
      else
        xml.at('//serviceResponse/authenticationSuccess').children.each do |node|
          if node.is_a? Nokogiri::XML::Element
            if !node.namespace || !node.namespace.prefix == 'cas'
              # TODO: support JSON encoding
              attrs[node.name] = YAML.load node.text.strip
            end
          end
        end
      end

      attrs
    end

    protected

    def success?
      @success ||= !!xml.at('//serviceResponse/authenticationSuccess')
    end

    def authentication_failure
      @authentication_failure ||= xml.at('//serviceResponse/authenticationFailure')
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

      @xml = Nokogiri::XML(response.body).remove_namespaces!
    end

    # initially borrowed from omniauth-cas
    def parse_user_info(node)
      return nil if node.nil?
      {}.tap do |hash|
        node.children.each do |e|
          unless e.kind_of?(Nokogiri::XML::Text) || e.name == 'proxies'
            # There are no child elements
            if e.element_children.count == 0
              if hash.has_key?(e.name)
                hash[e.name] = [hash[e.name]] if hash[e.name].is_a? String
                hash[e.name] << e.content
              else
                hash[e.name] = e.content
              end
            elsif e.element_children.count
              # JASIG style extra attributes
              if e.name == 'attributes'
                hash.merge!(parse_user_info(e))
              else
                hash[e.name] = [] if hash[e.name].nil?
                hash[e.name] = [hash[e.name]] if hash[e.name].is_a? String
                hash[e.name].push(parse_user_info(e))
              end
            end
          end
        end
      end
    end
  end
end
