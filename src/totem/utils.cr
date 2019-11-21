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

    module HashHelper
      def has_value?(source : Hash(String, String | Any), paths : Array(String)) : Any?
        return Any.new(source) if paths.size.zero?
        if value = source[paths.first]?
          return value.is_a?(Any) ? value : Any.new(value) if paths.size == 1

          has_value?(value.as_h, paths[1..-1]) if value.is_a?(Any) && value.as_h?
        end
      end

      def deep_search(source : Hash(String, String | Any), paths : Array(String)) : Any | Hash(String, Any)
        paths.each do |path|
          subtree = source[path]?
          unless subtree
            hash = Totem::Any.new(Hash(String, Any).new)
            source[path] = hash
            source = hash
            next
          end

          source = if subtree.is_a?(Any)
                     subtree.as_h
                   elsif subtree.is_a?(Hash)
                     subtree.as(Hash(String, Any))
                   else
                     hash = Hash(String, Any).new
                     source[path] = Any.new(hash)
                     hash
                   end
        end

        source
      end
    end

    extend FileHelper
    extend EnvHelper
    extend HashHelper
  end
end
