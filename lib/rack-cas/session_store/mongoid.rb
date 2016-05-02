module RackCAS
  module MongoidStore
    class Session
      include Mongoid::Document
      include Mongoid::Timestamps

      field :_id, type: String
      if defined? Moped::BSON
        # Mongoid < 4
        field :data, type: Moped::BSON::Binary, default: Moped::BSON::Binary.new(:generic, Marshal.dump({}))
      else
        # Mongoid 4
        field :data, type: BSON::Binary, default: BSON::Binary.new(Marshal.dump({}))
      end
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

    # Rack 2.0 method
    def find_session(env, sid)
      if sid.nil?
        sid = generate_sid
        data = nil
      else
        unless session = Session.where(_id: sid).first
          session = {}
          # force generation of new sid since there is no associated session
          sid = generate_sid
        end
        data = unpack(session['data'])
      end

      [sid, data]
    end

    # Rack 2.0 method
    def write_session(env, sid, session_data, options)
      cas_ticket = (session_data['cas']['ticket'] unless session_data['cas'].nil?)

      session = Session.find_or_initialize_by(_id: sid)
      success = session.update_attributes(data: pack(session_data), cas_ticket: cas_ticket)

      success ? session.id : false
    end

    # Rack 2.0 method
    def delete_session(env, sid, options)
      Session.where(_id: sid).delete

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
      if defined? Moped::BSON
        Moped::BSON::Binary.new(:generic, Marshal.dump(data))
      else
        BSON::Binary.new(Marshal.dump(data))
      end
    end

    def unpack(packed)
      return nil unless packed

      if defined? Moped::BSON
        Marshal.load(StringIO.new(packed.to_s))
      else
        Marshal.load(packed.data)
      end
    end
  end
end
