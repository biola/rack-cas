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
      RackCAS::URL.new(super.to_hash)
    end
  end
end