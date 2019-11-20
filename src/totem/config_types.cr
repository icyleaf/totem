module Totem
  # Config types
  module ConfigTypes
    @@adapters = {} of String => Adapter
    @@aliases = {} of String => String

    # Register config type
    #
    # ```
    # Totem::ConfigTypes.register(Totem::ConfigTypes::YAML.new, "yaml", "yml")
    # ```
    def self.register(adapter : Adapter, name : String, *shortcuts)
      @@adapters[name] = adapter
      shortcuts.each do |shortcut|
        next unless shortcut.is_a?(String)
        @@aliases[shortcut] = name
      end unless shortcuts.empty?
    end

    # Register config type with name
    #
    # DEPRECATED: Use `register` directly instead.
    #
    # ```
    # Totem::ConfigTypes.register_adapter("yaml", Totem::ConfigTypes::YAML.new)
    # ```
    def self.register_adapter(name : String, adapter : Adapter)
      @@adapters[name] = adapter
    end

    # Set alias for registered config type
    #
    # DEPRECATED: Use `register` directly instead.
    #
    # ```
    # Totem::ConfigTypes.register_alias("yml", "yaml")
    # ```
    def self.register_alias(shortcut : String, name : String)
      @@aliases[shortcut] = name
    end

    # Returns the value for the key given by *key*.
    def self.[](name : String)
      @@adapters[normalize(name)]
    end

    # Returns `true` when key given by *key* exists, otherwise `false`.
    def self.has_keys?(name : String)
      keys.includes?(name)
    end

    # Returns a new `Array` with all the keys.
    def self.keys
      @@adapters.keys.concat(@@aliases.keys)
    end

    private def self.normalize(name : String)
      @@aliases.fetch(name, name)
    end

    # Adapter of config type
    abstract class Adapter
      abstract def read(raw : String | IO) : Hash(String, Totem::Any)
      abstract def write(io : File, config : Config)

      protected def cast_to_any_hash(hash : Hash(_, Totem::Any::Type))
        hash.each_with_object(Hash(String, Totem::Any).new) do |(key, value), obj|
          key = case key
                when String
                  key
                when ::JSON::Any
                  key.as_s
                when ::YAML::Any
                  key.as_s
                else
                  key.to_s
                end

          obj[key] = Totem::Any.new(value)
        end
      end
    end
  end
end

# auto requires non-external dependency adapters
require "./config_types/json"
require "./config_types/yaml"
