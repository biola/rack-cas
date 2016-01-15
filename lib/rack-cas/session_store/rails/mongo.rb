require 'rack-cas/session_store/mongo'
require 'action_dispatch/middleware/session/abstract_store'

module ActionDispatch
  module Session
    class RackCasMongoStore < AbstractStore
      include RackCAS::MongoStore
    end
  end
end