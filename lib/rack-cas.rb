require 'rack-cas/configuration'
require 'rack-cas/railtie' if defined?(Rails)

module RackCAS
  def self.configure
    yield config
  end

  def self.config
    @config ||= Configuration.new
  end
end
