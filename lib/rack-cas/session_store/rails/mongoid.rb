require 'rack-cas/session_store/mongoid'
require 'action_dispatch/middleware/session/abstract_store'

module ActionDispatch
  module Session
    class RackCasMongoidStore < AbstractStore
      include RackCAS::MongoidStore
    end
  end
end