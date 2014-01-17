module RackCAS
  class Railtie < Rails::Railtie
    config.rack_cas = ActiveSupport::OrderedOptions.new

    initializer 'rack_cas.initialize' do |app|
      if config.rack_cas.fake || (config.rack_cas.fake.nil? && Rails.env.test?)
        require 'rack/fake_cas'
        app.middleware.use Rack::FakeCAS, config.rack_cas, config.rack_cas.fake_attributes
      elsif !config.rack_cas.server_url.nil? # for backwards compatibility
        require 'rack/cas'
        app.middleware.use Rack::CAS, config.rack_cas
      end
    end

    rake_tasks do
      load File.expand_path('../../tasks/session_prune.rake', __FILE__)
    end
  end
end
