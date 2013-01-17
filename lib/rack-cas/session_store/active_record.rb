module RackCAS
  module ActiveRecordStore
    class Session < ActiveRecord::Base
      attr_accessible :id, :data, :cas_ticket
    end

    def self.destroy_session_by_cas_ticket(cas_ticket)
      affected = Session.delete_all(cas_ticket: cas_ticket)
      affected == 1
    end

    private

    def get_session(env, sid)
      if sid.nil?
        sid = generate_sid
        data = nil
      else
        session = Session.where(session_id: sid).first || {}
        data = unpack(session['data'])
      end

      [sid, data]
    end

    def set_session(env, sid, session_data, options)
      cas_ticket = (session_data['cas']['ticket'] unless session_data['cas'].nil?)

      session = Session.find_or_initialize_by_session_id(sid)
      success = session.update_attributes(data: pack(session_data), cas_ticket: cas_ticket)

      success ? session.session_id : false
    end

    def destroy_session(env, sid, options)
      session = Session.where(session_id: sid).delete_all
      
      options[:drop] ? nil : generate_sid
    end

    def pack(data)
      ::Base64.encode64(Marshal.dump(data)) if data
    end

    def unpack(data)
      Marshal.load(::Base64.decode64(data)) if data
    end
  end
end
