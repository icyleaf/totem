require "json"

module Totem::ConfigTypes
  class JSON < Adapter
    def read(raw)
      ::JSON.parse(raw).as_h
    end

    def write(io, config)
      io.puts(config.settings.to_json)
    end
  end
end

Totem::ConfigTypes.register_adapter("json", Totem::ConfigTypes::JSON.new)
