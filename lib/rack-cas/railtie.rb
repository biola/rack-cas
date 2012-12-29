require 'rack/cas'

module RackCAS
  class Railtie < Rails::Railtie
    config.rack_cas = ActiveSupport::OrderedOptions.new

    initializer 'rack_cas.initialize' do |app|
      unless config.rack_cas.server_url.nil? # for backwards compatibility
        app.middleware.use Rack::CAS, config.rack_cas
      end
    end
  end
end
