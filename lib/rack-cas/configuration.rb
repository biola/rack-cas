module RackCAS
  class Configuration
    SETTINGS = [:server_url, :session_store, :exclude_path, :exclude_paths, :extra_attributes_filter, :verify_ssl_cert]

    SETTINGS.each do |setting|
      attr_accessor setting

      define_method "#{setting}?" do
        !(send(setting).nil? || send(setting) == [])
      end
    end

    def initialize
      @verify_ssl_cert = true
    end

    def extra_attributes_filter
      Array(@extra_attributes_filter)
    end

    def update(settings_hash)
      settings_hash.each do |setting, value|
        unless SETTINGS.include? setting.to_sym
          raise ArgumentError, "invalid setting: #{setting}"
        end

        self.public_send "#{setting}=", value
      end

      raise ArgumentError, 'server_url is required' unless server_url?
      if session_store? && !session_store.respond_to?(:destroy_session_by_cas_ticket)
        raise ArgumentError, 'session_store does not support single-sign-out'
      end
    end
  end
end
