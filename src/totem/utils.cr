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
    module EnvHelper
      def env_key(key : String, env_prefix : String? = nil)
        new_key = key.upcase
        if (prefix = env_prefix) && !prefix.empty?
          prefix = prefix[0..-2] if prefix[-1] == '_'
          return new_key.starts_with?(prefix) ? new_key : "#{prefix.upcase}_#{new_key}"
        end

        new_key
      end
    end

    extend FileHelper
    extend EnvHelper
  end
end
