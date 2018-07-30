module Totem
  module RemoteProviders
    @@providers = {} of String => Adapter.class

    def self.register_adapter(name : String, adapter : Adapter.class)
      @@providers[name] = adapter
    end

    def self.[](name : String)
      @@instance[name]
    end

    def self.keys
      @@providers.keys
    end

    def self.has_key?(key)
      keys.includes?(key)
    end

    @@instance = {} of String => Adapter

    def self.connect(name : String, config : Config, **options)
      cls = @@providers[name]
      options = options.merge({config: config})
      @@instance[name] = cls.new(**options)
    end

    abstract class Adapter
      abstract def read : Hash(String, Totem::Any::Type)?
      abstract def get(key : String) : Any
    end
  end
end
