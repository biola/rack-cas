require 'nokogiri'

class CASRequest
  attr_reader :request

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
    # The CAS protocol specifies that services must support tickets of
    # *up to* 32 characters in length (including ST-), and recommendes
    # that services accept tickets up to 256 characters long.
    # http://www.jasig.org/cas/protocol
    !!(@request.get? && ticket_param && ticket_param.to_s =~ /\AST\-[^\s]{1,253}\Z/)
  end

  def path_matches?(strings_or_regexps)
    Array(strings_or_regexps).any? do |matcher|
      if matcher.is_a? Regexp
        !!(@request.path_info =~ matcher)
      elsif matcher.to_s != ''
        @request.path_info[0...matcher.to_s.length] == matcher.to_s
      end
    end
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
