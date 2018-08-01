require "poncho"

module Totem::ConfigTypes
  class Env < Adapter
    def read(raw)
      Poncho.parse(raw).to_h
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

Totem::ConfigTypes.register_adapter("env", Totem::ConfigTypes::Env.new)
