require 'spec_helper'
require 'rack-cas/cas_request'

describe CASRequest do
  def app
    fake_cas_test_app
  end

  subject { CASRequest.new(last_request) }

  context 'ticket validation request' do
    before { get '/private/something?ticket=ST-0123456789ABCDEFGHIJKLMNOPQRS' }
    its(:ticket_validation?) { should be true }
    its(:ticket) { should eql 'ST-0123456789ABCDEFGHIJKLMNOPQRS' }
    its(:service_url) { should eql 'http://example.org/private/something' }
    its(:logout?) { should be false }
    its(:single_sign_out?) { should be false }
  end

  context 'ticket POST' do
    before { post '/private/something?ticket=ST-0123456789ABCDEFGHIJKLMNOPQRS&post=POST' }
    its(:ticket_validation?) { should be false }
    its(:ticket) { should be nil }
  end

  context 'invalid ticket' do
    before { get '/private/something?ticket=BL+ARG' }
    its(:ticket_validation?) { should be false }
    its(:ticket) { should be nil }
  end

  context 'short ticket' do
    before { get '/private/something?ticket=' }
    its(:ticket_validation?) { should be false }
    its(:ticket) { should be nil }
  end

  context 'single sign out request' do
    before { post "/?logoutRequest=#{URI.encode(fixture('single_sign_out_request.xml'))}" }
    its(:ticket) { should eql 'ST-0123456789ABCDEFGHIJKLMNOPQRS' }
    its(:single_sign_out?) { should be true }
    its(:logout?) { should be false }
    its(:ticket_validation?) { should be false }
  end

  context 'logout request' do
    before { get '/logout' }
    its(:logout?) { should be true }
    its(:service_url) { should eql 'http://example.org/logout' }
    its(:single_sign_out?) { should be false }
    its(:ticket_validation?) { should be false }
  end

  describe :path_matches? do
    context 'matching path' do
      before { get '/match/this/path/does' }
      ['/match', /this/, ['/blah', /match/]].each do |matcher|
        it { expect(subject.path_matches? matcher).to be true }
      end
    end

    context 'not-matching path' do
      before { get '/something/else/that/doesnt' }
      ['match', /match/, ['/foo', /bar/], [], nil, ''].each do |matcher|
        it { expect(subject.path_matches? matcher).to be false }
      end
    end
  end
end
