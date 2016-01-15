module RackCAS
  module MongoStore
    def collection
      @collection
    end

    def initialize(app, options = {})
      require 'mongo'

      unless options[:collection]
        raise "To avoid creating multiple connections to MongoDB, " +
              "the Mongo Session Store will not create it's own connection " +
              "to MongoDB - you must pass in a collection with the :collection option"
      end

      @collection = options[:collection].respond_to?(:call) ? options[:collection].call : options[:collection]

      super
    end

    private
    def get_session(env, sid)
      sid ||= generate_sid
      session = collection.find(_id: sid).first || {}
      [sid, unpack(session['data'])]
    end

    def set_session(env, sid, session_data, options = {})
      sid ||= generate_sid
      collection.update({'_id' => sid},
                        {'_id' => sid, 'data' => pack(session_data), 'updated_at' => Time.now},
                        upsert: true)
      sid # TODO: return boolean, right?
    end

    def pack(data)
      [Marshal.dump(data)].pack('m*')
    end

    def unpack(packed)
      return nil unless packed
      Marshal.load(packed.unpack('m*').first)
    end
  end
end