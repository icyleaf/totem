require "json"

module Totem::ConfigTypes
  # Builtin JSON format config type
  class JSON < Adapter
    def read(raw)
      ::JSON.parse(raw).as_h
    end

    def write(io, config)
      io.puts(config.settings.to_json)
    end
  end
end

Totem::ConfigTypes.register(Totem::ConfigTypes::JSON.new, "json")
