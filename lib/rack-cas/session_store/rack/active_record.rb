require 'rack/session/abstract/id'
require 'rack-cas/session_store/active_record'

module Rack
  module Session
    class RackCASActiveRecordStore < Rack::Session::Abstract::ID
      include RackCAS::ActiveRecordStore
    end
  end
end
