require 'rack-cas/session_store/redis'
require 'action_dispatch/middleware/session/abstract_store'

module ActionDispatch
  module Session
    class RackCasRedisStore < AbstractStore
      include RackCAS::RedisStore
    end
  end
end
