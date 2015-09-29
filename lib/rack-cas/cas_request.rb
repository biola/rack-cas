require 'addressable/uri'
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
    # The CAS protocol specifies that services must support tickets of
    # *up to* 32 characters in length (including ST-), and recommends
    # that services accept tickets up to 256 characters long.
    #
    # It also specifies that although the service ticket MUST start with "ST-",
    # the proxy ticket SHOULD start with "PT-".  The "ST-" validation has
    # been moved to the validate_service_url method in server.rb.
    #
    # http://jasig.github.io/cas/development/protocol/CAS-Protocol-Specification.html
    !!(@request.get? && ticket_param && ticket_param.to_s =~ /\A[^\s]{1,256}\Z/)
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

  def pgt_callback?
    !!(@request.get? && RackCAS.config.pgt_callback_url? && \
        Addressable::URI.parse(RackCAS.config.pgt_callback_url).path == Addressable::URI.parse(@request.url).path && \
        pgt_iou_param && pgt_iou_param.to_s =~ /\A[^\s]{1,256}\Z/ && \
        pgt_param && pgt_param.to_s =~ /\A[^\s]{1,256}\Z/)
  end

  def pgt
    pgt_param if pgt_callback?
  end

  def pgt_iou
    pgt_iou_param if pgt_callback?
  end

  private

  def ticket_param
    @request.params['ticket']
  end

  def pgt_iou_param
    @request.params['pgtIou']
  end

  def pgt_param
    @request.params['pgtId']
  end

  def sso_ticket
    xml = Nokogiri::XML(@request.params['logoutRequest'])
    node = xml.root.children.find { |c| c.name =~ /SessionIndex/i }
    node.text unless node.nil?
  end
end
