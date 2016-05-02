require 'spec_helper'
require 'rack-cas/configuration'

describe RackCAS::Configuration do
  subject { RackCAS::Configuration.new }

  context 'when the attribute is neither nil, an empty array, nor false' do
    before { subject.update(renew: true, verify_ssl_cert: true, server_url: 'https://cas.example.com/', exclude_paths: ['/api', /\.json/]) }

    [:renew?, :verify_ssl_cert?, :server_url?, :exclude_paths?].each do |att|
      describe "##{att}" do
        it('is true') { expect(subject.send(att)).to be true }
      end
    end
  end

  context 'when the attribute is nil, an empty array, or false' do
    before { subject.update(renew: nil, verify_ssl_cert: false, server_url: 'https://cas.example.com/', exclude_paths: []) }

    [:renew?, :verify_ssl_cert?, :exclude_paths?].each do |att|
      describe "##{att}" do
        it('is false') { expect(subject.send(att)).to be false }
      end
    end
  end
end
