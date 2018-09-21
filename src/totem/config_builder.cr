require "json"
require "./utils"

module Totem
  # Builder of Configuration
  #
  # #### Load config file
  #
  # ```
  # struct Config
  #   include Totem::ConfigBuilder
  #
  #   build do
  #     config_type "yaml"
  #     config_paths ["/etc", "~/.config/totem", "config/"]
  #   end
  # end
  #
  # config = Config.configure
  # config["name"] # => "foo"
  # ```
  #
  # #### Load config and mapping to struct
  #
  # ```
  # struct Profile
  #   include Totem::ConfigBuilder
  #
  #   property name : String
  #   property gender : String
  #
  #   build do
  #     config_type "yaml"
  #     config_paths ["/etc", "~/.config/totem", "config/"]
  #   end
  # end
  #
  # config = Profile.configure do |c|
  #   c.set_default("gender", "unkown")
  # end
  #
  # config.name     # => "foo"
  # config.gender   # => "unkown"
  # config["title"] # => "bar"
  # ```
  module ConfigBuilder
    @@config = Totem::Config.new

    macro included
      include Totem::Utils::FileHelper
      include JSON::Serializable

      def self.configure(file : String)
        load_wit_file(file)
        configure
      end

      def self.configure(file : String, &block)
        load_wit_file(file)
        configure(&block)
      end

      def self.configure
        @@config.load!
        @@config.mapping(self)
      end

      def self.configure(&block)
        @@config.load!
        yield @@config
        @@config.mapping(self)
      end

      private def self.load_wit_file(file)
        config_path = File.dirname(file)
        config_name = File.basename(file, File.extname(file))
        config_type = config_type(file)

        @@config.config_paths << config_path if config_path && !@@config.config_paths.includes?(config_path)
        @@config.config_type = config_type if config_type
        @@config.config_name = config_name
      end

      forward_missing_to @@config
    end

    # Build block
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
