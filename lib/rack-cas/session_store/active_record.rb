module RackCAS
  module ActiveRecordStore
    class Session < ActiveRecord::Base
    end

    def self.destroy_session_by_cas_ticket(cas_ticket)
      affected = Session.delete_all(cas_ticket: cas_ticket)
      affected == 1
    end

    def self.prune(after = nil)
      after ||= Time.now - 2592000 # 30 days ago
      Session.where('updated_at < ?', after).delete_all
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

      [sid, data || {}]
    end

    def set_session(env, sid, session_data, options={})
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

    def destroy_session(env, sid, options)
      Session.where(session_id: sid).delete_all

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
