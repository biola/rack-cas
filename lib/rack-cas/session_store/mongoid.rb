module RackCAS
  module MongoidStore
    class Session
      include Mongoid::Document
      include Mongoid::Timestamps

      field :_id, type: String
      field :data, type: Moped::BSON::Binary, :default => Moped::BSON::Binary.new(:generic,Marshal.dump({}))
      field :cas_ticket, type: String
    end

    def self.destroy_session_by_cas_ticket(cas_ticket)
      affected = Session.where(cas_ticket: cas_ticket).delete
      affected == 1
    end

    def self.prune(after = nil)
      after ||= Time.now - 2592000 # 30 days ago
      Session.where(:updated_at.lte => after).delete
    end

    private

    def get_session(env, sid)
      if sid.nil?
        sid = generate_sid
        data = nil
      else
        session = Session.where(_id: sid).first || {}
        data = unpack(session['data'])
      end

      [sid, data]
    end

    def set_session(env, sid, session_data, options)
      cas_ticket = (session_data['cas']['ticket'] unless session_data['cas'].nil?)

      session = Session.find_or_initialize_by(_id: sid)
      success = session.update_attributes(data: pack(session_data), cas_ticket: cas_ticket)

      success ? session.id : false
    end

    def destroy_session(env, sid, options)
      session = Session.where(_id: sid).delete
      
      options[:drop] ? nil : generate_sid
    end

    def pack(data)
      Moped::BSON::Binary.new(:generic,Marshal.dump(data))
    end

    def unpack(packed)
      return nil unless packed
      Marshal.load(StringIO.new(packed.to_s))
    end
  end
end
