require 'rack-cas/session_store/active_record'

module ActionDispatch
  module Session
    class RackCasActiveRecordStore < RackCAS::ActiveRecordStore
    end
  end
end
