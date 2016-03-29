require 'spec_helper'
require 'rack-cas/service_validation_response'

describe RackCAS::ServiceValidationResponse do
  before { stub_request(:get, /serviceValidate/).to_return(headers: {'Content-Type' => 'text/xml'}, body: fixture(fixture_filename)) }
  let(:url) { 'http://example.com/cas/serviceValidate?service=http%3A%2F%2Fexample.org%2Fwhatever%3F&ticket=ST-0123456789ABCDEFGHIJKLMNOPQRS' }
  let(:response) { RackCAS::ServiceValidationResponse.new(url) }
  subject { response }

  context 'rubycas-style response' do
    let(:fixture_filename) { 'rubycas_service_response.xml' }

    its(:user) { should eql 'johnd0' }

    describe :extra_attributes do
      subject { response.extra_attributes }
      it { should be_kind_of Hash }
      its(['eduPersonNickname']) { should eql ['John'] }
    end
  end

  context 'namespaces response' do
    let(:fixture_filename) { 'namespaces_response.xml' }

    its(:user) { should eql 'johnd0' }

    describe :extra_attributes do
      subject { response.extra_attributes }
      it { should be_kind_of Hash }
      its(['title']) { should eql ['Imaginary Person'] }
    end
  end

  context 'jasig-style response' do
    let(:fixture_filename) { 'jasig_service_response.xml' }

    its(:user) { should eql 'johnd0' }

    describe :extra_attributes do
      subject { response.extra_attributes }
      it { should be_kind_of Hash }
      its(['eduPersonAffiliation']) { should eql ['alumnus', 'employee'] }
      its(['eduPersonNickname']) { should eql 'John' }
    end
  end

  context 'nested jasig-style response' do
    let(:fixture_filename) { 'jasig_nested_service_response.xml' }

    its(:user) { should eql 'johnd0' }

    describe :extra_attributes do
      subject { response.extra_attributes }
      it { should be_kind_of Hash }
      its(['eduPersonAffiliation']) { should eql ['alumnus', 'employee'] }
      its(['eduPersonNickname']) { should eql 'John' }
      its(['nestedAttrs']) { should eql [{'attrType' => 'first'}, {'attrType' => 'second'}] }
      its(['mixedAttrs']) { should eql ['string value', {'crazyAttr' => 'crazy nested string'}] }
    end
  end

  context 'failure response' do
    let(:fixture_filename) { 'failure_service_response.xml' }

    it 'should raise an authentication failure exception' do
      expect{ subject.user }.to raise_error RackCAS::ServiceValidationResponse::AuthenticationFailure, 'Ticket ST-0123456789ABCDEFGHIJKLMNOPQRS not recognized'
      expect{ subject.extra_attributes}.to raise_error RackCAS::ServiceValidationResponse::AuthenticationFailure, 'Ticket ST-0123456789ABCDEFGHIJKLMNOPQRS not recognized'
    end
  end
end
