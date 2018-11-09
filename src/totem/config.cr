require "logger"
require "uri"
require "./utils"

module Totem
  # `Totem::Config` is the core configuration reader, parser and writer.
  #
  # The config type are avaiable in:
  #
  # - yaml/yml
  # - json
  # - env
  class Config
    include Totem::Utils::EnvHelper
    include Totem::Utils::FileHelper
    include Totem::Utils::HashHelper

    # Load configuration from a file
    #
    # ```
    # Totem::Config.from_file("config.yaml", ["/etc/totem", "~/.totem", "./"])
    # ```
    def self.from_file(file : String, paths : Array(String)? = nil, key_delimiter : String? = ".")
      config_name = File.basename(file, File.extname(file))
      config_type = Utils.config_type(file)
      instance = new(config_name, config_type, key_delimiter: key_delimiter)

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
    def self.parse(raw : String, type : String, key_delimiter : String? = ".")
      instance = new(config_type: type, key_delimiter: key_delimiter)
      instance.parse(raw)
      instance
    end

    CONFIG_NAME = "config"
    KEY_DELIMITER = "."

    getter config_file : String?
    property config_paths
    property config_name
    property config_type
    property key_delimiter
    getter env_prefix : String?

    @remote_provider : RemoteProviders::Adapter?

    def initialize(@config_name = CONFIG_NAME, @config_type : String? = nil,
                   @config_paths : Array(String) = [] of String, @key_delimiter = KEY_DELIMITER)
      @logger = Logger.new STDOUT, Logger::ERROR, formatter: default_logger_formatter
      @debugging = false
      @automatic_env = false

      @aliases = Hash(String, String).new
      @overrides = Hash(String, Any).new
      @config = Hash(String, Any).new
      @env = Hash(String, String).new
      @kvstores = Hash(String, Any).new
      @defaults = Hash(String, Any).new
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

    # Sets the default value for given key
    #
    # ```
    # totem.set_default("id", 123)
    # totem.set_default("user.name", "foobar")
    # ```
    def set_default(key : String, value : T) forall T
      set_value_from(@defaults, key, value)
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
      set_value_from(@overrides, key, value)
    end

    # Gets any value by given key
    #
    # The behavior of returning the value associated with the first
    # place from where it is set. following order:
    # - override
    # - env
    # - config file
    # - key/value store
    # - default
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

    # Similar to `get` method but returns `Nil` if key not exists.
    #
    # > Case-insensitive for a key.
    #
    # ```
    # totem.fetch("env")  => "development" or nil.
    # ```
    def fetch(key : String) : Any?
      if value = find(key)
        return value
      end
    end

    # Similar to `get` method but returns given value if key not exists.
    #
    # > Case-insensitive for a key.
    #
    # ```
    # totem.fetch("env", "development") => "development"
    # ```
    def fetch(key : String, default_value : (Any | Any::Type)) : Any
      if value = fetch(key)
        return value
      end

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
      env_key = real_key ? real_key.not_nil! : env_key(key, @env_prefix)
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

    # Add a remote provider
    #
    # Two arguments must passed:
    #
    # - `endpoint`: the url of endporint.
    # - `provider`: The name of provider, ignore it if endpoint's scheme is same as provider.
    #
    # #### Redis
    #
    # You can get value access the key:
    #
    # ```
    # totem.add_remote(provider: "redis", endpoint: "redis://user:pass@localhost:6379/1")
    # # Or make it shorter
    # totem.add_remote(endpoint: "redis://user:pass@localhost:6379/1")
    #
    # totem.get("user:id") # => "123"
    # ```
    #
    # You can get value from raw json access the path
    #
    # ```
    # totem.add_remote(endpoint: "redis://user:pass@localhost:6379/1", path: "config:production.json")
    # totem.get("user:id") # => "123"
    # ```
    def add_remote(provider : String? = nil, **options)
      raise RemoteProviderError.new("Missing the endpoint") unless endpoint = options[:endpoint]?

      provider = URI.parse(endpoint.not_nil!).scheme unless provider
      if (name = provider) && RemoteProviders.has_key?(name)
        @logger.info("Adding #{name}:#{endpoint} to remote config list")
        @remote_provider = RemoteProviders.connect(name, **options)
        kvstores = RemoteProviders[name].read(@config_type)
        if kvstores.nil? && (path = options[:path]?)
          raise RemoteProviderError.new("Can not read config with path: #{path}, make sure sets config_type before this call or named path with file extension.")
        end

        if kvstores
          kvstores.not_nil!.each do |key, value|
            set_value_from(@kvstores, key, value)
          end
        end
      else
        raise UnsupportedRemoteProviderError.new("Unsupport remote provider: #{provider}")
      end
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
      @config_type = config_type(file)

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

      unless extname = config_type(file)
        raise "Requires vaild extension name with file: #{file}"
      end

      unless ConfigTypes.has_keys?(extname)
        raise UnsupportedConfigError.new("Unsupport config type: #{extname}")
      end

      if !force && File.exists?(file)
        raise Error.new("File #{file} exists. Use write_config(force: true) to overwrite")
      end

      mode = "w"
      File.open(file, mode) do |f|
        ConfigTypes[extname].write(f, self)
      end
    end

    def clear!
      @config_name = CONFIG_NAME
      @config_type = nil
      @config_paths = [] of String
      @key_delimiter = KEY_DELIMITER

      @logger = Logger.new STDOUT, Logger::ERROR, formatter: default_logger_formatter
      @debugging = false
      @automatic_env = false

      @aliases = Hash(String, String).new
      @overrides = Hash(String, Any).new
      @config = Hash(String, Any).new
      @env = Hash(String, String).new
      @kvstores = Hash(String, Any).new
      @defaults = Hash(String, Any).new
    end

    # Debugging switch
    def debugging=(value : Bool)
      @logger.level = value ? Logger::DEBUG : Logger::ERROR
      @debugging = value
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
      mapping(converter)
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
    def mapping(converter : T.class, key : String? = nil) forall T
      raise MappingError.new("Not found the key in configuration: #{key}") if key && !has_key?(key.not_nil!)

      {% begin %}
        {{ struct_type = nil }}
        {% for ancestor in T.ancestors %}
          {% if ancestor == JSON::Serializable %}
            {{ struct_type = "json" }}
          {% elsif ancestor == YAML::Serializable %}
            {{ struct_type = "yaml" }}
          {% end %}
        {% end %}

        {% if struct_type != nil %}
          raw = key ? find(key.not_nil!).to_{{ struct_type.id }} : to_{{ struct_type.id }}
          converter.from_{{ struct_type.id }}(raw)
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
      unless (type = config_type) && ConfigTypes.has_keys?(type)
        raise UnsupportedConfigError.new("Unsupport config type: #{type}")
      end

      return unless data = ConfigTypes[type].read(raw)

      data.each do |key, value|
        set_value_from(@config, key, value)
      end
    end

    # Returns all keys holding a value, regardless of where they are set.
    #
    # Nested keys are returns with a `#key_delimiter` (= ".") separator.
    def flat_keys : Array(String)
      keys = flat_merge(@aliases, @overrides, @env, @config, @defaults, source: {} of String => Bool)
      keys.each_with_object([] of String) do |(key, _), obj|
        obj << key
      end
    end

    # Returns an iterator over the key of `#settings` entries.
    def keys
      settings.keys
    end

    # Returns an iterator over the `#settings` entries.
    def each
      settings.each do |key, value|
        yield key, value
      end
    end

    # Returns all settings of configuration.
    def settings : Hash(String, Any)
      flat_keys.each_with_object({} of String => Any) do |key, obj|
        next unless value = find(key)

        paths = key.split(@key_delimiter)
        last_key = paths.last.downcase

        hash = deep_search(obj, paths[0..-2])
        hash[last_key] = value
      end
    end

    # Alias to `#settings`
    def to_h
      settings
    end

    def set_value_from(source : Hash(String, Totem::Any), key : String, value : T) forall T
      key = real_key(key.downcase)

      paths = key.split(@key_delimiter)
      last_key = paths.last.downcase

      deep_hash = deep_search(source, paths[0..-2])
      deep_hash[last_key] = Any.new(value)
    end

    private def find(key : String) : Any?
      paths = key.split(@key_delimiter)
      nested = paths.size > 1
      # return if nested && shadow_path?(paths, @aliases).empty?

      key = real_key(key)
      paths = key.split(@key_delimiter)
      nested = paths.size > 1

      # Override
      if value = has_value?(@overrides, paths)
        return value
      end
      # return if nested && shadow_path?(paths, @overrides).empty?

      # Env
      if @automatic_env && (value = env_value?(key))
        return Any.new(value.as(String))
        # return unless shadow_path?(paths)
      end

      if (env_key = @env[key]?) && (value = env_value?(env_key))
        return Any.new(value.as(String))
      end
      # return if nested && shadow_path?(paths, @env).empty?

      # Config
      if value = has_value?(@config, paths)
        return value
      end
      # return if nested && shadow_path?(paths, @config).empty?

      # key/value store
      if value = has_value?(@kvstores, paths)
        return value
      end

      if (provider = @remote_provider) && (value = provider.get(key))
        return value
      end

      # Default
      if value = has_value?(@defaults, paths)
        return value
      end
      # return if nested && shadow_path?(paths, @defaults).empty?
    end

    # Return paths if given paths is shadowed somewhere in given hash
    private def shadow_path?(paths : Array(String), hash : Hash(String, String | Any)) : String
      paths.each_with_index do |_, i|
        return "" unless value = has_value?(hash, paths[0..i])

        if value.is_a?(Any) && value.as_h?
          next
        else
          return paths[0..i].join(@key_delimiter)
        end
      end

      ""
    end

    # Return paths if given paths is shadowed somewhere in the ENV
    private def shadow_path?(paths : Array(String)) : String?
      paths.each_with_index do |_, i|
        key = paths[0..i].join(@key_delimiter)
        if value = env_value?(key)
          return value
        end
      end
    end

    private def flat_merge(*targets, source : Hash(String, Bool), prefix : String = "")
      targets.each do |target|
        raise Error.new("Can not merge with #{target.class}") unless target.is_a?(Hash)
        source = flat_merge(target, source, prefix)
      end

      source
    end

    private def flat_merge(target : Hash(String, String | Any), source : Hash(String, Bool), prefix : String = "")
      return source if !source.empty? && !prefix.empty? && source.has_key?(prefix)

      subtree = {} of String => Any
      prefix += @key_delimiter unless prefix.empty?
      target.each do |key, value|
        full_key = "#{prefix}#{key}"
        if value.is_a?(Hash)
          subtree = value
        elsif value.is_a?(Totem::Any) && (temp_value = value.as(Totem::Any).as_h?)
          subtree = temp_value
        else
          source[full_key.downcase] = true
          next
        end

        source = flat_merge(subtree, source, full_key)
      end

      source
    end

    private def find_config
      @logger.debug("Searching for config in #{@config_paths}")
      @config_paths.each do |path|
        if file = search_config(path)
          return file
        end
      end

      raise NotFoundConfigFileError.new("Not found config file #{@config_name} in #{@config_paths}")
    end

    private def search_config(path : String)
      unless Dir.exists?(path)
        @logger.debug("Skip: config path is not exists in `#{path}`")
        return
      end

      @logger.debug("Searching for config in #{path}")
      if (config_type = @config_type) && (file = config_file(path, config_type))
        return file
      else
        ConfigTypes.keys.each do |ext|
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

    private def real_key(key : String) : String
      key = key.downcase
      if @aliases.has_key?(key)
        new_key = @aliases[key]
        @logger.debug("Alias #{key} to #{new_key}")
        return new_key
      end
      key
    end

    private def env_value?(key : String) : String?
      ENV[env_key(key, @env_prefix)]?
    end

    private def default_logger_formatter
      Logger::Formatter.new do |severity, datetime, _, message, io|
        io << sprintf("%-6s", severity) << datetime.to_s("%F %T") << " " << message
      end
    end

    # :nodoc:
    def inspect_body(pretty_print = false)
      newline = pretty_print ? "\n" : ""
      String.build do |io|
        io << "#<" << self.class << newline
        io << " @config_paths=" << @config_paths << "," << newline
        io << " @config_name=\"" << @config_name << "\"" << "," << newline
        io << " @config_type=\"" << @config_type << "\"" << "," << newline
        io << " @key_delimiter=\"" << @key_delimiter << "\"" << "," << newline
        io << " @automatic_env=" << @automatic_env << "," << newline
        io << " @env_prefix=" << (@env_prefix.nil? ? "nil" : %Q{"#{@env_prefix}"}) << "," << newline
        io << " @aliases=" << @aliases << "," << newline
        io << " @overrides=" << @overrides << "," << newline
        io << " @config=" << @config << "," << newline
        io << " @env=" << @env << "," << newline
        io << " @kvstores=" << @kvstores << "," << newline
        io << " @defaults=" << @defaults << ">"
      end
    end

    # :nodoc:
    def inspect(io)
      io << inspect_body(false)
    end

    # :nodoc:
    def pretty_print(pp : PrettyPrint)
      pp.text(inspect_body(true))
    end

    # :nodoc:
    def to_json(json)
      settings.to_json(json)
    end

    # :nodoc:
    def to_yaml(yaml)
      settings.to_yaml(yaml)
    end
  end
end
