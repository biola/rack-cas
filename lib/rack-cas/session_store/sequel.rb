require 'sequel'

module RackCAS
  module SequelStore
    class Session < Sequel::Model; end

    def self.destroy_session_by_cas_ticket(cas_ticket)
      affected = Session.where(cas_ticket: cas_ticket).delete
      affected == 1
    end

    def self.prune(after = nil)
      after ||= Time.now - 2592000 # 30 days ago
      Session.where { updated_at < after }.delete
    end

    private

    def find_session(env, sid)
      if sid.nil?
        sid = generate_sid
        data = nil
      else
        unless session = Session.first(session_id: sid)
          session = Session.new
          sid = generate_sid
        end
        data = unpack(session.data)
      end

      [sid, data]
    end

    def write_session(req, sid, session_data, options)
      cas_ticket = (session_data['cas']['ticket'] unless session_data['cas'].nil?)
      data = pack(session_data)

      begin
        if session = Session.find(session_id: sid)
          session.update(data: data, cas_ticket: cas_ticket)
        else
          Session.create(session_id: sid, data: data, cas_ticket: cas_ticket)
        end
      rescue Sequel::Error
        false
      else
        sid
      end
    end

    def delete_session(req, sid, options)
      Session.where(session_id: sid).delete
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
