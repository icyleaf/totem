require "poncho"

module Totem::ConfigTypes
  # DotEnv format Config Type
  #
  # **Note**: It dependency [poncho](https://github.com/icyleaf/poncho) shard. Install it before use.
  class Env < Adapter
    def read(raw : String | IO) : Hash(String, Totem::Any)
      cast_to_any_hash(Poncho.parse(raw).to_h)
    end

    def write(io, config)
      config.flat_keys.sort.each do |key|
        next unless value = config[key]?
        real_key = key.gsub(config.key_delimiter, "_").upcase
        io << real_key << "=" << value << "\n"
      end
    end
  end
end

Totem::ConfigTypes.register(Totem::ConfigTypes::Env.new, "env", "dotenv")
