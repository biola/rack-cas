require 'nokogiri'

class CASRequest
  def initialize(request)
    @request = request
  end

  def ticket
    @ticket ||= if single_sign_out?
      xml = Nokogiri::XML(@request.params['logoutRequest']).tap do |xml|
        xml.remove_namespaces!
      end
      node = xml.at('/LogoutRequest/SessionIndex')
      node.text unless node.nil?
    else
      @request.params['ticket']
    end
  end

  def service_url
    RackCAS::URL.parse(@request.url).remove_param('ticket').to_s
  end

  def logout?
    @request.path_info == '/logout'
  end

  def single_sign_out?
    !!@request.params['logoutRequest']
  end

  def ticket_validation?
    !!@request.params['ticket']
  end
end