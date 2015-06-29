require 'spec_helper'

describe Rack::CAS do
  let(:server_url) { 'http://example.com/cas' }
  let(:app_options) { {'fake' => false} }
  let(:ticket) { 'ST-0123456789ABCDEFGHIJKLMNOPQRS' }

  def app
    cas_test_app app_options
  end

  describe 'public request' do
    subject { get '/public' }
    its(:status) { should eql 200 }
  end

  describe 'auth required request' do
    subject { get '/private' }
    its(:status) { should eql 302 }
    its(:location) { should match %r{http://example.com/cas/login\?service=http%3A%2F%2Fexample.org%2Fprivate} }
  end

  describe 'ticket validation request' do
    subject { get '/private?search=blah&ticket=ST-0123456789ABCDEFGHIJKLMNOPQRS' }
    its(:status) { should eql 302 }
    its(:location) { should eql 'http://example.org/private?search=blah' }

    context 'without additional query parameters' do
      subject { get '/private?ticket=ST-0123456789ABCDEFGHIJKLMNOPQRS' }
      its(:status) { should eql 302 }
      its(:location) { should eql 'http://example.org/private' }
    end

    context 'with extra_attributes_filter set' do
      let(:app_options) { { extra_attributes_filter: [:cn, :mail] } }

      before { get '/private?ticket=ST-0123456789ABCDEFGHIJKLMNOPQRS' }
      subject { last_request.session['cas']['extra_attributes'] }
      it { should have_key 'cn' }
      it { should have_key 'mail' }
      it { should_not have_key 'title' }
    end

    context 'with an invalid ticket' do
      before { RackCAS::ServiceValidationResponse.any_instance.stub(:user) { raise RackCAS::ServiceValidationResponse::TicketInvalidError } }
      its(:status) { should eql 302 }
      its(:location) { should eql 'http://example.com/cas/login?service=http%3A%2F%2Fexample.org%2Fprivate%3Fsearch%3Dblah' }
    end
  end

  describe 'logout request' do
    context 'without params' do
      subject { get '/logout' }
      its(:status) { should eql 302 }
      its(:location) { should eql 'http://example.com/cas/logout' }
    end

    context 'with params' do
      subject { get '/logout', gateway: 'true', service: 'http://example.com' }
      its(:status) { should eql 302 }
      its(:location) { should eql 'http://example.com/cas/logout?gateway=true&service=http%3A%2F%2Fexample.com' }
    end
  end

  describe 'single sign out request' do
    let(:app_options) {
      session_store = double('session_store')
      session_store.stub(:destroy_session_by_cas_ticket).and_return 1
      session_store.should_receive(:destroy_session_by_cas_ticket).with(ticket)

      { session_store: session_store }
    }

    subject { post "/?logoutRequest=#{URI.encode(fixture('single_sign_out_request.xml'))}" }
    its(:status) { should eql 200 }
    its(:body) { should eql 'CAS Single-Sign-Out request intercepted.' }
  end

  describe 'excluded request' do
    let(:app_options) { { exclude_path: '/private', session_store: nil } }

    subject { get '/private' }
    its(:status) { should eql 401 }
    its(:body) { should eql 'Authorization Required' }
  end
end
