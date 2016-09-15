require 'rack-cas/session_store/sequel'
require 'action_dispatch/middleware/session/abstract_store'

module ActionDispatch
  module Session
    class RackCasSequelStore < AbstractStore
      include RackCAS::SequelStore
    end
  end
end
