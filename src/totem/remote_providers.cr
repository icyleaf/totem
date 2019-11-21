module Totem
  # Remote provider
  module RemoteProviders
    @@providers = {} of String => Adapter.class

    # Registe remote provider with name
    #
    # ```
    # Totem::ConfigTypes.register_adapter("redis", Totem::RemoteProvider::Redis)
    # ```
    def self.register_adapter(name : String, adapter : Adapter.class)
      @@providers[name] = adapter
    end

    # Returns the value for the key given by *key*.
    def self.[](name : String)
      @@instance[name]
    end

    # Returns a new `Array` with all the keys.
    def self.keys
      @@providers.keys
    end

    # Returns `true` when key given by *key* exists, otherwise `false`.
    def self.has_key?(key)
      keys.includes?(key)
    end

    @@instance = {} of String => Adapter

    # Connect remote provider with options
    def self.connect(name : String, **options)
      cls = @@providers[name]
      @@instance[name] = cls.new(**options)
    end

    # Adapter of remote provider
    abstract class Adapter
      abstract def read(config_type : String? = nil) : Hash(String, Totem::Any::Type)?
      abstract def get(key : String) : Any?
    end
  end
end
