require 'spec_helper'
require 'rack-cas/cas_request'

describe CASRequest do
  def app
    fake_cas_test_app
  end

  subject { CASRequest.new(last_request) }

  context 'ticket validation request' do
    before { get '/private/something?ticket=ST-0123456789ABCDEFGHIJKLMNOPQRS' }
    its(:ticket_validation?) { should be_true }
    its(:ticket) { should eql 'ST-0123456789ABCDEFGHIJKLMNOPQRS' }
    its(:service_url) { should eql 'http://example.org/private/something' }
    its(:logout?) { should be_false }
    its(:single_sign_out?) { should be_false }
  end

  context 'ticket POST' do
    before { post '/private/something?ticket=ST-0123456789ABCDEFGHIJKLMNOPQRS&post=POST' }
    its(:ticket_validation?) { should be_false }
    its(:ticket) { should be_nil }
  end

  context 'invalid ticket' do
    before { get '/private/something?ticket=BLARG' }
    its(:ticket_validation?) { should be_false }
    its(:ticket) { should be_nil }
  end

  context 'short ticket' do
    before { get '/private/something?ticket=ST-0123456789' }
    its(:ticket_validation?) { should be_false }
    its(:ticket) { should be_nil }
  end

  context 'single sign out request' do
    before { post "/?logoutRequest=#{URI.encode(fixture('single_sign_out_request.xml'))}" }
    its(:ticket) { should eql 'ST-0123456789ABCDEFGHIJKLMNOPQRS' }
    its(:single_sign_out?) { should be_true }
    its(:logout?) { should be_false }
    its(:ticket_validation?) { should be_false }
  end

  context 'logout request' do
    before { get '/logout' }
    its(:logout?) { should be_true }
    its(:service_url) { should eql 'http://example.org/logout' }
    its(:single_sign_out?) { should be_false }
    its(:ticket_validation?) { should be_false }
  end

  describe :path_matches? do
    context 'matching path' do
      before { get '/match/this/path/does' }
      ['/match', /this/, ['/blah', /match/]].each do |matcher|
        it { expect(subject.path_matches? matcher).to be_true }
      end
    end

    context 'not-matching path' do
      before { get '/something/else/that/doesnt' }
      ['match', /match/, ['/foo', /bar/], [], nil, ''].each do |matcher|
        it { expect(subject.path_matches? matcher).to be_false }
      end
    end
  end
end