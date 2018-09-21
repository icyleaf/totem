require "json"

module Totem
  # Builder of Configuration
  module ConfigBuilder
    @@config = Totem::Config.new

    macro included
      include JSON::Serializable

      def self.configure
        @@config.load!
        @@config.mapping(self)
      end

      def self.configure(&block)
        @@config.load!
        yield @@config
        @@config.mapping(self)
      end
    end

    macro build
      def self.config_paths(paths : Array(String))
        @@config.config_paths = paths
      end

      def self.config_name(name : String)
        @@config.config_name = name
      end

      def self.config_type(type : String)
        @@config.config_type = type
      end

      def self.key_delimiter(delimiter : String)
        @@config.key_delimiter = delimiter
      end

      def self.env_prefix(prefix : String)
        @@config.env_prefix = prefix
      end

      def self.env_prefix(prefix : String)
        @@config.env_prefix = prefix
      end

      def self.automatic_env(status : Bool)
        @@config.automatic_env = status
      end

      def self.automatic_env(env_prefix : String)
        @@config.automatic_env(env_prefix)
      end

      def self.debugging(status : Bool)
        @@config.debugging = status
      end

      {{ yield }}
    end
  end
end
