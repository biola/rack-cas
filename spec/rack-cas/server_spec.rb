require 'spec_helper'
require 'rack-cas/server'

describe RackCAS::Server do
  let(:server_url) { 'http://example.com/cas' }
  let(:server) { RackCAS::Server.new(server_url) }
  let(:service_url) { 'http://example.org/whatever' }
  let(:ticket) { 'ST-0123456789ABCDEFGHIJKLMNOPQRS' }

  describe :login_url do
    subject { server.login_url(service_url) }
    its(:to_s) { should eql 'http://example.com/cas/login?service=http%3A%2F%2Fexample.org%2Fwhatever' }
  end

  describe :logout_url do
    subject { server.logout_url.to_s }
    it { should eql 'http://example.com/cas/logout' }
  end

  describe :validate_service do
    subject { server.validate_service(service_url, ticket) }
    its(:length) { should eql 2 }
    its(:first) { should eql 'johnd0' }
    its(:last) { should be_kind_of Hash }
  end

  describe :validate_service_url do    
    subject { server.send(:validate_service_url, service_url, ticket) }
    its(:to_s) { should eql 'http://example.com/cas/serviceValidate?service=http%3A%2F%2Fexample.org%2Fwhatever&ticket=ST-0123456789ABCDEFGHIJKLMNOPQRS'}
  end
end