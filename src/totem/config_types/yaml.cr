require "yaml"

module Totem::ConfigTypes
  class YAML < Adapter
    def read(raw)
      raise Error.new("Can not parse config file to hash.") unless data = ::YAML.parse(raw).as_h?
      data.each_with_object(Hash(String, Totem::Any).new) do |(key, value), obj|
        obj[key.to_s.downcase] = Totem::Any.new(value)
      end
    end

    def write(io, config)
      io.puts(config.settings.to_yaml)
    end
  end
end

Totem::ConfigTypes.register_adapter("yaml", Totem::ConfigTypes::YAML.new)
Totem::ConfigTypes.register_alias("yml", "yaml")
