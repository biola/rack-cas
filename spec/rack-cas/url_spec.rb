require 'spec_helper'
require 'rack-cas/url'

describe RackCAS::URL do
  let(:url_string) { 'http://example.com/path?param1=value1&param2=value2' }
  let(:url) { RackCAS::URL.parse(url_string) }

  describe :append_path do
    subject { url.append_path('appended-path') }
    its(:path) { should eql '/path/appended-path' }
  end

  describe :add_params do
    subject { url.add_params(appended: 'param') }
    its(:query) { should eql 'appended=param&param1=value1&param2=value2' }
  end

  describe :remove_param do
    subject { url.remove_param('param1') }
    its(:query) { should eql 'param2=value2' }
  end

  describe :dup do
    subject { url.dup }
    it { should be_kind_of RackCAS::URL }
    its(:to_s) { should eql url.to_s }
    its(:to_hash) { should eql Addressable::URI.parse(url_string).to_hash }
  end
end