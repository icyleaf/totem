require "json"
require "./utils"

module Totem
  # Builder of Configuration
  #
  # #### Load config
  #
  # ```
  # struct Config
  #   include Totem::ConfigBuilder
  #
  #   build do
  #     config_type "yaml"
  #     config_paths ["/etc", "~/.config/totem", "config"]
  #   end
  # end
  #
  # config = Config.configure
  # config["name"] # => "foo"
  # ```
  #
  # #### Load config with custom file
  #
  # ```
  # struct Config
  #   include Totem::ConfigBuilder
  #
  #   build do
  #     config_type "yaml"
  #     config_paths ["/etc", "~/.config/totem", "config"]
  #   end
  # end
  #
  # config = Config.configure("/path/to/config/config.example.json")
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
      include JSON::Serializable

      def self.configure(file : String, position : Int = -1, enviroment : String? = nil)
        load_with_file(file, position, enviroment)
        configure(enviroment)
      end

      def self.configure(file : String, position : Int = -1, enviroment : String? = nil, &block : Totem::Config -> _)
        load_with_file(file, position, enviroment)
        configure(enviroment, &block)
      end

      def self.configure(enviroment : String? = nil)
        load_with_env!(enviroment)
        @@config.mapping(self)
      end

      def self.configure(enviroment : String? = nil, &block : Totem::Config -> _)
        load_with_env!(enviroment)
        yield @@config
        @@config.mapping(self)
      end

      private def self.load_with_file(file, position, enviroment)
        config_path = File.dirname(file)
        config_name = File.basename(file, File.extname(file))
        config_type = Totem::Utils.config_type(file)

        @@config.config_paths.insert(position, config_path) if config_path && !@@config.config_paths.includes?(config_path)
        @@config.config_type = config_type if config_type
        @@config.config_name = config_name
      end

      private def self.load_with_env!(enviroment)
        @@config.config_env = enviroment if enviroment
        @@config.load!
      end

      forward_missing_to @@config
    end

    # Build block
    macro build
      def self.config_paths(value : Array(String))
        @@config.config_paths = value
      end

      def self.config_name(value : String)
        @@config.config_name = value
      end

      def self.config_type(value : String)
        @@config.config_type = value
      end

      def self.config_env(value : String)
        @@config.config_env = value
      end

      def self.config_envs(value : Array(String))
        @@config.config_envs = value
      end

      def self.key_delimiter(value : String)
        @@config.key_delimiter = value
      end

      def self.env_prefix(value : String)
        @@config.env_prefix = value
      end

      def self.env_prefix(value : String)
        @@config.env_prefix = value
      end

      def self.automatic_env(value : Bool)
        @@config.automatic_env = value
      end

      def self.automatic_env(value : String)
        @@config.automatic_env(value)
      end

      def self.debugging(value : Bool)
        @@config.debugging = value
      end

      {{ yield }}
    end
  end
end
