require 'rack-cas/session_store/sequel'
require 'rack/session/abstract/id'

module Rack
  module Session
    class RackCasSequelStore < Rack::Session::Abstract::Persisted
      include RackCAS::SequelStore
    end
  end
end
