module RackCAS
  module RedisStore
    class Session
      @client = nil

      def self.client
        @client ||= (RackCAS.config.redis_options? ? Redis.new(RackCAS.config.redis_options) : Redis.new)
        return @client
      end

      def self.find_by_id(session_id)
        session = self.client.get("rack_cas_session:#{session_id}")
        session ? {'sid' => session_id, 'data' => session} : session
      end

      def self.write(session_id:, data:, cas_ticket: )
        #create a row with the session_id and the data
        #create a row with the cas_ticket acting as a reverse index
        results = self.client.pipelined do
          self.client.set("rack_cas_session:#{session_id}",data)
          self.client.expireat("rack_cas_session:#{session_id}",30.days.from_now.to_i)
          self.client.set("rack_cas_ticket:#{cas_ticket}","rack_cas_session:#{session_id}")
          self.client.expireat("rack_cas_ticket:#{cas_ticket}",30.days.from_now.to_i)
        end

        results == ["OK",true,"OK",true] ? session_id : false
      end

      def self.destroy_by_cas_ticket(cas_ticket)
        session_id = self.client.get("rack_cas_ticket:#{cas_ticket}")
        results = self.client.pipelined do
          self.client.del("rack_cas_ticket:#{cas_ticket}")
          self.client.del(session_id)
        end
        return results[1]
      end

      def self.delete(session_id)
        self.client.del("rack_cas_session:#{session_id}")
      end
    end

    def self.destroy_session_by_cas_ticket(cas_ticket)
      affected = Session.destroy_by_cas_ticket(cas_ticket)
      affected == 1
    end

    #we don't need to prune because the keys expire automatically
    def self.prune(after = nil)
    end

    private


    # Rack 2.0 method
    def find_session(env, sid)
      if sid.nil?
        sid = generate_sid
        data = nil
      else
        unless session = Session.find_by_id(sid)
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

      success = Session.write(session_id: sid, data: pack(session_data), cas_ticket: cas_ticket)

      success ? sid : false
    end

    # Rack 2.0 method
    def delete_session(env, sid, options)
      Session.delete(sid)

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
