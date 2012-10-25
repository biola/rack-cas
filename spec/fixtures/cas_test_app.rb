$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'
require 'rack/cas'

class CasTestApp
  def call(env)
    request = Rack::Request.new(env)

    if request.path_info =~ /private/
      [ 401, {'Content-Type' => 'text/plain'}, ['Authorization Required'] ]
    else
      [ 200, {'Content-Type' => 'text/plain'}, ['Public Page'] ]
    end
  end
end