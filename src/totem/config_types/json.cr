require "json"

module Totem::ConfigTypes
  class JSON < Adapter
    def read(raw)
      raise Error.new("Can not parse config file to hash.") unless data = ::JSON.parse(raw).as_h?
      data.each_with_object(Hash(String, Totem::Any).new) do |(key, value), obj|
        obj[key.downcase] = Totem::Any.new(value)
      end
    end

    def write(io, config)
      io.puts(config.settings.to_json)
    end
  end
end

Totem::ConfigTypes.register_adapter("json", Totem::ConfigTypes::JSON.new)
