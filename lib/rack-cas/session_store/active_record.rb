require 'rack/session/abstract/id'

module RackCAS
  class ActiveRecordStore < Rack::Session::Abstract::PersistedSecure

    class Session < ActiveRecord::Base
    end

    def self.destroy_session_by_cas_ticket(cas_ticket)
      affected = Session.where(cas_ticket: cas_ticket).delete_all
      affected == 1
    end

    def self.prune(after = nil)
      after ||= Time.now - 2592000 # 30 days ago
      Session.where('updated_at < ?', after).delete_all
    end

    private

    # Rack 2.0 method
    def find_session(env, sid)
      if sid.nil?
        sid = generate_sid
        data = nil
      else
        unless session = Session.where(session_id: sid.private_id).first
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
        Session.where(session_id: sid.private_id).first_or_initialize
      else
        Session.find_or_initialize_by_session_id(sid.private_id)
      end
      session.data = pack(session_data)
      session.cas_ticket = cas_ticket
      success = session.save

      success ? sid : false
    end

    # Rack 2.0 method
    def delete_session(req, sid, options)
      Session.where(session_id: sid.private_id).delete_all
      Session.where(session_id: sid.public_id).delete_all

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
