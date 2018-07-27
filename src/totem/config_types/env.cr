require "poncho"

module Totem::ConfigTypes
  class Env < Adapter
    def read(raw)
      data = Poncho.parse(raw)
      Hash(String, Totem::Any).new.tap do |obj|
        data.each do |key, value|
          obj[key.downcase] = Any.new(value)
        end
      end
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
