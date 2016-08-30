module RackCAS
  module ActiveRecordStore
    class ProxyGrantingTicketIou < ActiveRecord::Base
    end

    class Session < ActiveRecord::Base
    end

    def self.create_proxy_granting_ticket(pgt_iou, pgt)
      ProxyGrantingTicketIou.create!(proxy_granting_ticket_iou: pgt_iou, proxy_granting_ticket: pgt)
    end

    def self.proxy_granting_ticket_for(pgt_iou)
      proxy_granting_ticket_iou = ProxyGrantingTicketIou.where(proxy_granting_ticket_iou: pgt_iou).first || nil
      proxy_granting_ticket_iou.proxy_granting_ticket if proxy_granting_ticket_iou
    end

    def self.destroy_session_by_cas_ticket(cas_ticket)
      affected = Session.delete_all(cas_ticket: cas_ticket)
      affected == 1
    end

    def self.prune(after = nil)
      after ||= Time.now - 2592000 # 30 days ago
      Session.where('updated_at < ?', after).delete_all
      ProxyGrantingTicketIou.where('updated_at < ?', after).delete_all
    end

    private

    # Rack 2.0 method
    def find_session(env, sid)
      if sid.nil?
        sid = generate_sid
        data = nil
      else
        unless session = Session.where(session_id: sid).first
          session = {}
          # force generation of new sid since there is no associated session
          sid = generate_sid
        end
        data = unpack(session['data'])
      end

      [sid, data]
    end

    # Rack 2.0 method
    def write_session(req, sid, session_data, options)
      cas_ticket = (session_data['cas']['ticket'] unless session_data['cas'].nil?)

      session = if ActiveRecord.respond_to?(:version) && ActiveRecord.version >= Gem::Version.new('4.0.0')
        Session.where(session_id: sid).first_or_initialize
      else
        Session.find_or_initialize_by_session_id(sid)
      end
      session.data = pack(session_data)
      session.cas_ticket = cas_ticket
      success = session.save

      success ? session.session_id : false
    end

    # Rack 2.0 method
    def delete_session(req, sid, options)
      Session.where(session_id: sid).delete_all

      options[:drop] ? nil : generate_sid
    end

    # Rack 1.* method
    alias get_session find_session

    # Rack 1.* method
    def set_session(env, sid, session_data, options) # rack 1.x compatibilty
      write_session(Rack::Request.new(env), sid, session_data, options)
    end

    # Rack 1.* method
    def destroy_session(env, sid, options) # rack 1.x compatibilty
      delete_session(Rack::Request.new(env), sid, options)
    end

    def pack(data)
      ::Base64.encode64(Marshal.dump(data)) if data
    end

    def unpack(data)
      Marshal.load(::Base64.decode64(data)) if data
    end
  end
end
