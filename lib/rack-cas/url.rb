require 'addressable/uri'

module RackCAS
  class URL < Addressable::URI
    def append_path(path)
      self.tap do |u|
        u.path = (u.path.split('/') + [path]).join('/')
      end
    end

    def add_params(params)
      self.tap do |u|
        u.query_values = (u.query_values || {}).tap do |qv|
          params.each do |key, value|
            qv[key] = value
          end
        end
      end
    end

    def remove_param(param)
      remove_params(Array(param))
    end

    # params can be an array or a hash
    def remove_params(params)
      self.tap do |u|
        u.query_values = (u.query_values || {}).tap do |qv|
          params.each do |key, value|
            qv.delete key
          end
        end
      end
    end

    def dup
      duplicated_uri = RackCAS::URL.new(
        :scheme => self.scheme ? self.scheme.dup : nil,
        :user => self.user ? self.user.dup : nil,
        :password => self.password ? self.password.dup : nil,
        :host => self.host ? self.host.dup : nil,
        :port => self.port,
        :path => self.path ? self.path.dup : nil,
        :query => self.query ? self.query.dup : nil,
        :fragment => self.fragment ? self.fragment.dup : nil
      )
      return duplicated_uri
    end
  end
end