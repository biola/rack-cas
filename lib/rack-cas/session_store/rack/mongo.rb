require 'rack-cas/session_store/mongo'
require 'rack/session/abstract/id'

module Rack
  module Session
    class RackCASMongoStore < Rack::Session::Abstract::ID
      include RackCAS::MongoStore
    end
  end
end