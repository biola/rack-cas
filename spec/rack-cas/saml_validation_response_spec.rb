require 'spec_helper'
require 'rack-cas/saml_validation_response'

describe RackCAS::SAMLValidationResponse do
  before { stub_request(:post, /samlValidate/).to_return(headers: { 'Accept' => '*/*', 'Content-Type' => 'application/soap+xml; charset=utf-8' }, body: fixture(fixture_filename)) }
  let(:url) { 'http://example.com/cas/samlValidate?TARGET=http%3A%2F%2Fexample.org%2F' }
  let(:ticket) { 'ST-718673-vjzOrfL70HlOb5TviNTT-odo-665.example.org' }
  let(:response) { RackCAS::SAMLValidationResponse.new(url, ticket) }
  subject { response }

  context 'saml_validation_response' do
    let(:fixture_filename) { 'saml_validation_response.xml' }

    its(:user) { should eql 'johnd0' }

    describe :extra_attributes do
      subject { response.extra_attributes }
      it { should be_kind_of Hash }
      its(['eduPersonNickname']) { should eql 'John' }
    end
  end

  context 'failure response' do
    let(:fixture_filename) { 'failure_saml_response.xml' }

    it 'should raise an authentication failure exception' do
      expect{ subject.user }.to raise_error RackCAS::SAMLValidationResponse::AuthenticationFailure, "ticket 'ST-718673-vjzOrfL70HlOb5TviNTT-odo-665.example.org' not recognized"
      expect{ subject.extra_attributes}.to raise_error RackCAS::SAMLValidationResponse::AuthenticationFailure, "ticket 'ST-718673-vjzOrfL70HlOb5TviNTT-odo-665.example.org' not recognized"
    end
  end
end

