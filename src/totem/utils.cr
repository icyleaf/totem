module Totem
  module Utils
    module FileHelper
      def config_type(file)
        ext = File.extname(file)
        ext.size > 1 ? ext[1..-1] : nil
      end
    end

    module BoolHelper
      def as_bool?(value : String)
        value == "true" ? true : (value == "false" ? false : nil)
      end
    end

    extend BoolHelper
    extend FileHelper
  end
end
