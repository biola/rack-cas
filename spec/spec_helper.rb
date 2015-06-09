$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'rspec/its'
require 'bundler/setup'
require 'rspec'
require 'rack'
require 'rack/test'
require 'webmock/rspec'
require 'rack-cas'
require 'rack/cas'
require 'rack/fake_cas'
require 'fixtures/cas_test_app'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before do
    stub_request(:get, /serviceValidate/).to_return(
      headers: {'Content-Type' => 'text/xml'},
      body: fixture('rubycas_service_response.xml')
    )

    stub_request(:post, /samlValidate/).to_return(
      headers: {'Content-Type' => 'text/xml'},
      body: fixture('saml_validation_response.xml')
    )
  end
end

def cas_test_app(options = {})
  Rack::CAS.new(CasTestApp.new, {server_url: 'http://example.com/cas'}.merge(options))
end

def fake_cas_test_app
  Rack::FakeCAS.new(CasTestApp.new)
end

def fixture(filename)
  File.read File.expand_path(File.dirname(__FILE__) + "/fixtures/#{filename}")
end
