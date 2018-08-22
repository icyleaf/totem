require "etcd"
require "json"

module Totem::RemoteProviders
  class Etcd < Adapter
    def initialize(endpoint : String, @path : String? = nil)
      # etcd-crystal is not allow pass scheme.
      endpoint = endpoint.gsub("http://", "").gsub("https://", "")
      @client = ::Etcd.client(endpoint)
    end

    def read(config_type : String? = nil)
      if (path = @path) && (value = get?(path))
        return if value.nil?
        config_type = Utils.config_type(path) unless config_type
        if (name = config_type) && ConfigTypes.has_keys?(name)
          return ConfigTypes[name].read(value)
        end
      end
    end

    def get(key : String) : Any?
      if value = get?(key)
        Any.new(value)
      end
    end

    def get?(key)
      key = "/#{key}" unless key.starts_with?("/")
      @client.get(key).value
    rescue ::Etcd::KeyNotFound
      nil
    end
  end
end

Totem::RemoteProviders.register_adapter("etcd", Totem::RemoteProviders::Etcd)
