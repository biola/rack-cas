require 'spec_helper'
require 'rack-cas/configuration'

describe RackCAS::Configuration do
    
  it 'returns true for attribute? if the attribute is neither nil, an empty array, nor false' do
    configuration = RackCAS::Configuration.new
    configuration.update(renew: true, verify_ssl_cert: true, server_url: 'https://cas.example.com/', exclude_paths: ['/api', /\.json/])
    expect(configuration.renew?).to be true
    expect(configuration.verify_ssl_cert?).to be true
    expect(configuration.server_url?).to be true
    expect(configuration.exclude_paths?).to be true
  end

  it 'returns false for attribute? if the attribute is either nil, an empty array, or false' do
    configuration = RackCAS::Configuration.new
    configuration.update(renew: nil, verify_ssl_cert: false, server_url: 'https://cas.example.com/', exclude_paths: [])
    expect(configuration.renew?).to be false
    expect(configuration.verify_ssl_cert?).to be false
    expect(configuration.exclude_paths?).to be false
  end

end