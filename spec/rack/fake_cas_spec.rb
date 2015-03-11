require 'spec_helper'

describe Rack::FakeCAS do
  def app
    fake_cas_test_app
  end

  describe 'public request' do
    subject { get '/public' }
    its(:status) { should eql 200 }
    its(:body) { should_not match /username/ }
    its(:body) { should_not match /password/ }
  end

  describe 'auth required request' do
    subject { get '/private' }
    its(:status) { should eql 200 }
    its(:body) { should match /username/ }
    its(:body) { should match /password/ }
  end

  describe 'login page request' do
    subject { get '/fake_cas_login' }
    its(:status) { should eql 200 }
    its(:body) { should match /username/ }
    its(:body) { should match /password/ }
  end

  describe 'login request' do
    before { get '/login', username: 'janed0', service: 'http://example.org/private' }

    subject { last_response }
    it { should be_redirect }
    its(:location) { should eql 'http://example.org/private' }

    describe 'session' do
      subject { last_request.session['cas'] }
      it { should_not be_nil }
      its(['user']) { should eql 'janed0' }
      its(['extra_attributes']) { should eql({}) }
    end
  end

  describe 'logout request' do
    before { get '/logout' }

    subject { last_response }
    it { should be_redirect }
    its(:location) { should eql '/'}

    describe 'session' do
      subject { last_request.session }
      it { should eql({}) }
    end
  end

  describe 'excluded request' do
    def app
      Rack::FakeCAS.new(CasTestApp.new, exclude_path: '/private')
    end

    subject { get '/private' }
    its(:status) { should eql 401 }
    its(:body) { should eql 'Authorization Required' }
  end

  describe 'extra attributes' do
    def app
      Rack::FakeCAS.new(CasTestApp.new, {}, {
                          'janed0' => {
                            'name' => 'Jane Doe',
                            'email' => 'janed0@gmail.com'}
                        })
    end

    before { get '/login', username: 'janed0', service: 'http://example.org/private' }

    describe 'session' do
      subject { last_request.session['cas'] }
      it { should_not be_nil }
      its(['extra_attributes']) { should eql({'name' => 'Jane Doe',
                                              'email' => 'janed0@gmail.com'}) }
    end
  end
end
