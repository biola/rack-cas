require 'rack-cas/session_store/redis'
require 'rack/session/abstract/id'

module Rack
  module Session
    class RackCASRedisStore < Rack::Session::Abstract::ID
      include RackCAS::RedisStore
    end
  end
end
