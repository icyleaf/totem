require "yaml"

module Totem::ConfigTypes
  # Builtin YAML format config type
  class YAML < Adapter
    def read(raw)
      data = ::YAML.parse(raw).as_h
      data.each_with_object(Hash(String, ::YAML::Any).new) do |(key, value), obj|
        obj[key.to_s] = value
      end
    end

    def write(io, config)
      io.puts(config.settings.to_yaml)
    end
  end
end

Totem::ConfigTypes.register(Totem::ConfigTypes::YAML.new, "yaml", "yml")
