require 'rack-cas/session_store/active_record'
require 'action_dispatch/middleware/session/abstract_store'

module ActionDispatch
  module Session
    class RackCasActiveRecordStore < AbstractStore
      include RackCAS::ActiveRecordStore
    end
  end
end