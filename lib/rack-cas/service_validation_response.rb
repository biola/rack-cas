module RackCAS
  class ServiceValidationResponse
    class AuthenticationFailure < StandardError; end

    REQUEST_HEADERS = { 'Accept' => '*/*' }
    
    def initialize(url)
      @url = URL.parse(url)
    end

    def user
      if success?
        xml.xpath('/cas:serviceResponse/cas:authenticationSuccess/cas:user').text
      else
        raise AuthenticationFailure, failure_message
      end
    end

    def extra_attributes
      attrs = {}

      raise AuthenticationFailure, failure_message unless success?

      # Jasig style
      if attr_node = xml.at('/cas:serviceResponse/cas:authenticationSuccess/cas:attributes')
        attr_node.children.each do |node|
          if node.is_a? Nokogiri::XML::Element
            attrs[node.name] = node.text
          end
        end

      # RubyCas-Server style
      else
        xml.at('/cas:serviceResponse/cas:authenticationSuccess').children.each do |node|
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
      @success ||= !!xml.at('/cas:serviceResponse/cas:authenticationSuccess')
    end

    def failure_message
      if node = xml.at('/cas:serviceResponse/cas:authenticationFailure')
        node.text.strip
      end
    end

    def response
      require 'net/http'
      return @response unless @response.nil?
      
      http = Net::HTTP.new(@url.host, @url.inferred_port)
      http.use_ssl = true if @url.scheme == 'https'

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