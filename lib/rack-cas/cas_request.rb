require 'nokogiri'

class CASRequest
  def initialize(request)
    @request = request
  end

  def ticket
    @ticket ||= if single_sign_out?
      sso_ticket
    elsif ticket_validation?
      ticket_param
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
    # The CAS protocol specifies 32 characters as the minimum length of a
    # service ticket (including ST-) http://www.jasig.org/cas/protocol
    !!(@request.get? && ticket_param && ticket_param.to_s =~ /\AST\-[^\s]{29}/)
  end

  private

  def ticket_param
    @request.params['ticket']
  end

  def sso_ticket
    xml = Nokogiri::XML(@request.params['logoutRequest'])
    node = xml.root.children.find { |c| c.name =~ /SessionIndex/i }
    node.text unless node.nil?
  end
end