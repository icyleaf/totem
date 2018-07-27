module Totem
  module ConfigTypes
    @@adapters = {} of String => Adapter
    @@aliases = {} of String => String

    def self.register_adapter(name : String, adapter : Adapter)
      @@adapters[name] = adapter
    end

    def self.register_alias(shortcut : String, name : String)
      @@aliases[shortcut] = name
    end

    def self.[](name : String)
      @@adapters[normalize(name)]
    end

    def self.[]?(name : String)
      @@adapters[normalize(name)]?
    end

    def self.has_adapter?(name : String)
      adapter_names.includes?(name)
    end

    def self.adapter_names
      @@adapters.keys.concat(@@aliases.keys)
    end

    private def self.normalize(name : String)
      @@aliases.fetch(name, name)
    end

    abstract class Adapter
      abstract def parse(raw : String | IO) : Hash(String, Totem::Any)
      abstract def store(io : File, config : Config)
    end
  end
end

# auto requires non-external dependency adapters
require "./config_types/json"
require "./config_types/yaml"
