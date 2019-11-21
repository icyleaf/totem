require "yaml"

module Totem::ConfigTypes
  # Builtin YAML format config type
  class YAML < Adapter
    def read(raw) : Hash(String, Totem::Any)
      cast_to_any_hash(::YAML.parse(raw).as_h)
    end

    def write(io, config)
      io.puts(config.settings.to_yaml)
    end
  end
end

Totem::ConfigTypes.register(Totem::ConfigTypes::YAML.new, "yaml", "yml")
