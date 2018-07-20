require "json"
require "yaml"
require "poncho"
require "logger"

module Totem
  # `Totem::Config` is the core configuration reader, parser and writer.
  #
  # The config type are avaiable in:
  #
  # - yaml/yml
  # - json
  # - env
  class Config
    SUPPORTED_EXTS = %w(yaml yml json env)

    # Load configuration from a file
    #
    # ```
    # Totem::Config.from_file("config.yaml", ["/etc/totem", "~/.totem", "./"])
    # ```
    def self.from_file(file : String, paths : Array(String)? = nil)
      config_name = File.basename(file, File.extname(file))
      config_type = Utils.config_type(file)
      instance = new(config_name, config_type)

      if config_paths = paths
        config_paths.each do |path|
          instance.config_paths << path
        end
      else
        instance.config_paths << File.dirname(file)
      end

      instance.load!
      instance
    end

    # Parse configuration from a raw string.
    def self.parse(raw : String, type : String)
      instance = new(config_type: type)
      instance.parse(raw)
      instance
    end

    getter config_file : String?
    property config_paths
    property config_name
    property config_type
    property config_delimiter

    getter env_prefix : String?

    @aliases = Hash(String, String).new
    @overrides = Hash(String, Any).new
    @config = Hash(String, Any).new
    @env = Hash(String, String).new
    @defaults = Hash(String, Any).new

    def initialize(@config_name = "config", @config_type : String? = nil,
                   @config_paths : Array(String) = [] of String,
                   @config_delimiter = ".",
                   @automatic_env = false)
      @logger = Logger.new STDOUT, Logger::ERROR, formatter: default_logger_formatter
      @logging = false
    end

    # Sets the default value for given key
    #
    # ```
    # totem.set_default("id", 123)
    # totem.set_default("user.name", "foobar")
    # ```
    def set_default(key : String, value : T) forall T
      key = real_key(key.downcase)

      paths = key.split(@config_delimiter)
      last_key = paths.last.downcase

      deep_hash = deep_search(@defaults, paths[0..-2])
      deep_hash[last_key] = Any.new(value)
    end

    # Sets the default values with `Hash` data
    #
    # ```
    # totem.set_defaults({
    #   "id"   => 123,
    #   "user" => {
    #     "name" => "foobar",
    #   },
    # })
    # ```
    def set_defaults(defaults : Hash(String, _))
      defaults.each do |key, value|
        set_default(key, value)
      end
    end

    # Alias to `set` method.
    #
    # ```
    # totem["id"] = 123
    # totem["user.name"] = "foobar"
    # ```
    def []=(key : String, value : T) forall T
      set(key, value)
    end

    # Alias to `get` method.
    #
    # ```
    # totem["id"]
    # totem["user.name"]
    # ```
    def [](key : String) : Any
      get(key)
    end

    # Alias to `fetch` method but return `Nil` if not exists.
    #
    # ```
    # totem["id"]?
    # totem["user.name"]?
    # ```
    def []?(key : String) : Any?
      find(key)
    end

    # Checks to see if the key has been set in any of the data locations.
    #
    # > Case-insensitive for a key.
    def has_key?(key : String) : Bool
      find(key) ? true : false
    end

    # Sets the value for the key in the override regiser.
    #
    # Will be used instead of values obtained via config file, env, default.
    #
    # > Case-insensitive for a key.
    #
    # ```
    # totem.set("id", 123)
    # totem.set("user.name", "foobar")
    # ```
    def set(key : String, value : T) forall T
      key = real_key(key.downcase)

      paths = key.split(@config_delimiter)
      last_key = paths.last.downcase

      deep_hash = deep_search(@overrides, paths[0..-2])
      deep_hash[last_key] = Any.new(value)
    end

    # Gets any value by given key
    #
    # The behavior of returning the value associated with the first
    # place from where it is set. following order:
    # override, flag, env, config file, default
    #
    # > Case-insensitive for a key.
    #
    # ```
    # totem.get("id")
    # totem.get("user.name")
    # ```
    def get(key : String) : Any
      if value = find(key)
        return value
      end

      raise NotFoundConfigKeyError.new("Not found config: #{key}")
    end

    # Similar to `get` method but returns given value if key not exists.
    #
    # > Case-insensitive for a key.
    #
    # ```
    # totem.fetch("env", "development")
    # ```
    def fetch(key : String, default_value : (Any | Any::Type)? = nil) : Any?
      if value = find(key)
        return value
      end

      return if default_value.nil?

      default_value.is_a?(Any) ? default_value : Any.new(default_value)
    end

    # Register an aliase
    #
    # ```
    # totem.set("food", "apple")
    # totem.alias("f", "food")
    #
    # totem.set("user.name", "foobar")
    # totem.alias("username", "user.name")
    # ```
    def alias(alias_key : String, key : String)
      @aliases[alias_key.downcase] = key.downcase
    end

    # Bind a key to a ENV vairable
    #
    # If only a key is provided, it will use the `ENV` key matching the key, upcased.
    #
    # It will append env prefix when `env_prefix` is seted and the key is not provided.
    #
    # > Case-sensitive for a key.
    #
    # ```
    # totem.bind_env("HOME")
    # totem.bind_env("root_path", "HOME")
    #
    # totem.get("home")
    # totem.get("root_path")
    # ```
    def bind_env(key : String, real_key : String? = nil)
      key = key.downcase
      env_key = if real_key
                  real_key.not_nil!
                else
                  env_key(key)
                end

      @env[key] = env_key
    end

    # Defines a `ENV` prefix
    #
    # If defined with "totem", Totem will look for env variables that start with "TOTEM_"
    #
    # > It always upcase the prefix.
    #
    # ```
    # ENV["TOTEM_ENV"] = "development"
    #
    # totem.env_prefix = "totem"
    # totem.bind_env("env")
    # totem.get("env") # => "development"
    # ```
    def env_prefix=(prefix : String)
      @env_prefix = prefix.upcase
    end

    # Enable and load ENV variables to Totem to search.
    #
    # It provide an argument to quick define the env prefix(`env_prefix=`)
    #
    # ```
    # ENV["TOTEM_ENV"] = "development"
    #
    # totem.automatic_env("totem")
    # totem.get("env") # => "development"
    # ```
    def automatic_env(prefix : String? = nil)
      @env_prefix = prefix.not_nil!.upcase if prefix
      @automatic_env = true
    end

    # Load configuration file from disk, searching in the defined paths.
    #
    # ```
    # totem = Totem.new("config")
    # totem.config_paths << "/etc/totem" << "~/.totem"
    # begin
    #   totem.load!
    # rescue e
    #   puts "Fatal error config file: #{e.message}"
    # end
    # ```
    def load!
      return unless file = find_config
      load_file!(file)
    end

    # Load configuration file by given file name.
    #
    # It will ignore the values of `config_name`, `config_type` and `config_paths`.
    #
    # ```
    # totem = Totem.new("config", "json")
    # totem.config_paths << "/etc/totem" << "~/.totem"
    #
    # begin
    #   totem.load_file!("~/config/development.yaml")
    # rescue e
    #   puts "Fatal error config file: #{e.message}"
    # end
    # ```
    def load_file!(file : String)
      @logger.info("Attempting to read in config file")
      @logger.debug("Reading file: #{file}")

      @config_file = file
      @config_type = Utils.config_type(file)
      parse(File.open(file))
    end

    # Store the current configuration to a file.
    #
    # ```
    # totem = Totem.new("config", "json")
    # totem.config_paths << "/etc/totem" << "~/.totem"
    #
    # begin
    #   totem.store!
    # rescue e
    #   puts "Fatal error config file: #{e.message}"
    # end
    # ```
    def store!
      if file = @config_file
        raise Error.new("Config file is empty") if file.empty?
        store_file!(file, true)
      end

      raise Error.new("Config file is not be setted")
    end

    # Store current configuration to a given file.
    #
    # It will ignore the values of `config_name`, `config_type` and `config_paths`.
    #
    # ```
    # totem = Totem.new("config", "json")
    #
    # begin
    #   totem.store_file!("~/config.yaml", force: true)
    # rescue e
    #   puts "Fatal error config file: #{e.message}"
    # end
    # ```
    def store_file!(file : String, force : Bool = false)
      @logger.info("Attempting to write configuration to file: #{file}")

      unless extname = Utils.config_type(file)
        raise "Requires vaild extension name with file: #{file}"
      end

      unless SUPPORTED_EXTS.includes?(extname)
        raise UnsupportedConfigError.new(file)
      end

      if !force && File.exists?(file)
        raise "File #{file} exists. Use write_config(force: true) to overwrite"
      end

      mode = "w"
      File.open(file, mode) do |f|
        case extname
        when "yaml", "yml"
          f.puts(raw.to_yaml)
        when "json"
          f.puts(raw.to_json)
        when "env"
          # TODO
          raise Error.new("Not complete store file with dotenv.")
        end
      end
    end

    # Debugging switch
    def debugging=(value : Bool)
      @logger.level = value ? Logger::DEBUG : Logger::ERROR
      @logging = value
    end

    # Mapping JSON/YAML Serializable to Struct
    #
    # ```
    # struct Profile
    #   include JSON::Serializable
    #   # or
    #   # include YAML::Serializable
    #
    #   property name : String
    #   property hobbies : Array(String)
    #   property age : Int32
    #   property eyes : String
    # end
    #
    # profile = totem.mapping(Profile)
    # profile.name # => "steve"
    # ```
    def mapping(converter : T.class) forall T
      {% begin %}
        {{ struct_type = nil }}
        {% for ancestor in T.ancestors %}
          {% if ancestor == JSON::Serializable %}
            {{ struct_type = "json" }}
          {% elsif ancestor == YAML::Serializable %}
            {{ struct_type = "yaml" }}
          {% end %}
        {% end %}

        {% if struct_type == "json" %}
          converter.from_json to_json
        {% elsif struct_type == "yaml" %}
          converter.from_yaml to_yaml
        {% else %}
          raise MappingError.new("Can not mapping with class: #{T}, avaiable in JSON::Serializable, YAML::Serializable")
        {% end %}
      {% end %}
    end

    # Mapping JSON/YAML Serializable to Struct with key
    #
    # ```
    # struct Clothes
    #   include JSON::Serializable
    #   # or
    #   # include YAML::Serializable
    #
    #   property jacket : String
    #   property trousers : String
    #   property pants : Hash(String, String)
    # end
    #
    # clothes = totem.mapping(Clothes, "clothing")
    # clothes.jacket # => "leather"
    # ```
    def mapping(converter : T.class, key : String) forall T
      NotFoundConfigKeyError.new("Not found the key in configuration: #{key}") unless has_key?(key)

      {% begin %}
        {{ struct_type = nil }}
        {% for ancestor in T.ancestors %}
          {% if ancestor == JSON::Serializable %}
            {{ struct_type = "json" }}
          {% elsif ancestor == YAML::Serializable %}
            {{ struct_type = "yaml" }}
          {% end %}
        {% end %}

        {% if struct_type == "json" %}
          converter.from_json raw[key].to_json
        {% elsif struct_type == "yaml" %}
          converter.from_yaml raw[key].to_json
        {% else %}
          raise MappingError.new("Can not mapping with class: #{T.class}, avaiable in JSON::Serializable, YAML::Serializable")
        {% end %}
      {% end %}
    end

    # Parse raw string with given config type to configuration
    #
    # The config type are avaiable in:
    #
    # - yaml/yml
    # - json
    # - env
    def parse(raw : String | IO, config_type = @config_type)
      unless (type = config_type) && SUPPORTED_EXTS.includes?(type)
        raise UnsupportedConfigError.new("Unspoort config type: #{type}")
      end

      data = case type
             when "yaml", "yml"
               YAML.parse(raw).as_h
             when "json"
               JSON.parse(raw).as_h
             when "env"
               Poncho.parse(raw)
             end

      return unless data

      data.each do |key, value|
        key = key.to_s if key.is_a?(YAML::Any)
        @config[key.downcase] = Any.new(value)
      end
    end

    private def find(key : String) : Any?
      paths = key.split(@config_delimiter)
      nested = paths.size > 1
      # return if nested && shadow_path?(paths, @aliases).empty?

      key = real_key(key)
      paths = key.split(@config_delimiter)
      nested = paths.size > 1

      # Override
      if value = has_value?(@overrides, paths)
        return value
      end
      # return if nested && shadow_path?(paths, @overrides).empty?

      # Env
      if @automatic_env && (value = ENV[env_key(key)]?)
        return Any.new(value.as(String))
        return unless shadow_path?(paths)
      end
      if (env_key = @env[key]?) && (value = ENV[env_key(env_key)]?)
        return Any.new(value.as(String))
      end
      # return if nested && shadow_path?(paths, @env).empty?

      # Config
      if value = has_value?(@config, paths)
        return value
      end
      # return if nested && shadow_path?(paths, @config).empty?

      # Default
      if value = has_value?(@defaults, paths)
        return value
      end
      # return if nested && shadow_path?(paths, @defaults).empty?
    end

    private def has_value?(source : Hash(String, String | Any), paths : Array(String)) : Any?
      return Any.new(source) if paths.size.zero?
      if value = source[paths.first]?
        return value.is_a?(Any) ? value : Any.new(value) if paths.size == 1

        has_value?(value.as_h, paths[1..-1]) if value.is_a?(Any) && value.as_h?
      end
    end

    # Return paths if given paths is shadowed somewhere in given hash
    private def shadow_path?(paths : Array(String), hash : Hash(String, String | Any)) : String
      paths.each_with_index do |_, i|
        return "" unless value = has_value?(hash, paths[0..i])

        if value.is_a?(Any) && value.as_h?
          next
        else
          return paths[0..i].join(@config_delimiter)
        end
      end

      ""
    end

    private def deep_search(source : Hash(String, String | Any), paths : Array(String)) : Hash(String, Any)
      paths.each do |path|
        subtree = source[path]?

        unless subtree
          hash = Hash(String, Any).new
          source[path] = Any.new(hash)
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

    # Return paths if given paths is shadowed somewhere in the ENV
    private def shadow_path?(paths : Array(String)) : String?
      paths.each_with_index do |_, i|
        key = paths[0..i].join(@config_delimiter)
        if value = ENV[env_key(key)]?
          return value
        end
      end
    end

    private def find_config
      @logger.debug("Searching for config in #{@config_paths}")
      @config_paths.each do |path|
        if (file = search_config(path))
          return file
        end
      end

      raise NotFoundConfigFileError.new("Not found config file #{@config_name} in #{@config_paths}")
    end

    private def search_config(path : String) : String?
      @logger.debug("Searching for config in #{path}")
      if (content_type = @config_type) && (file = config_file(path, config_type))
        return file
      else
        SUPPORTED_EXTS.each do |ext|
          if file = config_file(path, ext)
            return file
          end
        end
      end
    end

    private def config_file(path, extname)
      file = File.join(path, "#{@config_name}.#{extname}")
      # Converts to an absolute path
      file = file.sub("$HOME", "~/") if file.starts_with?("$HOME")
      file = File.expand_path(file)
      @logger.debug("Checking for #{file}")

      if File.exists?(file) && File.readable?(file)
        @logger.debug("Found: #{file}")
        file
      end
    end

    private def real_key(key : String)
      key = key.downcase
      if @aliases.has_key?(key)
        new_key = @aliases[key]
        @logger.debug("Alias #{key} to #{new_key}")
        return new_key
      end
      key
    end

    private def env_key(key : String)
      new_key = key.upcase
      if (prefix = @env_prefix) && !prefix.empty?
        new_key.starts_with?(prefix) ? new_key : "#{prefix}_#{new_key}"
      else
        new_key
      end
    end

    def raw
      (@defaults.merge(@config)).merge(@overrides)
    end

    private def default_logger_formatter
      Logger::Formatter.new do |severity, datetime, progname, message, io|
        io << severity << " " << datetime.to_s("%F %T") << " " << message
      end
    end

    # :nodoc:
    def to_json(json)
      raw.to_json(json)
    end

    # :nodoc:
    def to_yaml(yaml)
      raw.to_yaml(yaml)
    end
  end
end
