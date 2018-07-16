module Totem
  module Utils
    module FileHelper
      def config_type(file : String)
        name = File.basename(file)
        name = "xxx.#{name}" if name.starts_with?(".")
        ext = File.extname(name)
        ext.size > 1 ? ext[1..-1] : nil
      end
    end

    module BoolHelper
      def as_bool?(value : String)
        value = value.downcase
        value == "true" ? true : (value == "false" ? false : nil)
      end
    end

    extend BoolHelper
    extend FileHelper
  end
end
