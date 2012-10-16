require 'rack-cas/session_store/mongoid'
require 'rack/session/abstract/id'

module Rack
  module Session
    class MongoidStore < Rack::Session::Abstract::ID
      include RackCAS::MongoidStore
    end
  end
end