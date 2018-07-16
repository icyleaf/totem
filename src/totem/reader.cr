require "json"
require "yaml"
require "logger"

module Totem
  class Reader
    SUPPORTED_EXTS = %w(yaml yml json)

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

      instance.read
      instance
    end

    def self.parse(raw : String, type : String)
      instance = new(config_type: type)
      instance.parse(raw)
      instance
    end

    property config_paths
    property config_name
    property config_type

    getter config_file : String?
    getter env_prefix : String?

    @config = Hash(String, Any).new
    @defaults = Hash(String, Any).new
    @env = Hash(String, String).new
    @aliases = Hash(String, String).new

    def initialize(@config_name = "config", @config_type : String? = nil, @config_paths : Array(String) = [] of String)
      @logger = Logger.new STDOUT, Logger::ERROR, formatter: default_logger_formatter
      @logging = false
    end

    def set_defaults(defaults : Hash(String, _))
      defaults.each do |key, value|
        set_default(key, value)
      end
    end

    def has_key?(key : String)
      @aliases.has_key?(key) || @config.has_key?(key) || @defaults.has_key?(key)
    end

    def set_default(key : String, value : T) forall T
      @defaults[key] = Any.new(value)
    end

    def set(key : String, value : T) forall T
      @config[key] = Any.new(value)
    end

    def get(key : String) : Any
      key = alias_key(key)

      if value = @config[key]?
        return value
      end

      if value = @defaults[key]?
        return value
      end

      raise NotFoundConfigKeyError.new("Not found config: #{key}")
    end

    def register_alias(alias_key : String, key : String)
      @aliases[alias_key.downcase] = key.downcase
    end

    # Mapping JSON Serializable Only to Struct
    #
    # TODO: how to detect converter's ancestors was XXX::Serializable
    def mapping(converter : _)
      converter.from_json to_json
    end

    def mapping(converter : _, key : String)
      NotFoundConfigKeyError.new("Not found the key in configuration: #{key}") unless has_key?(key)
      converter.from_json raw[key].to_json
    end

    def read
      return unless file = find_config
      read(file)
    end

    def read(file : String)
      @logger.info("Attempting to read in config file")
      @logger.debug("Reading file: #{file}")

      @config_file = file
      @config_type = Utils.config_type(file)
      parse(File.open(file))
    end

    def parse(raw : String | IO, config_type = @config_type)
      unless (type = config_type) && SUPPORTED_EXTS.includes?(type)
        raise UnsupportedConfigError.new("Unspoort config type: #{type}")
      end

      data = case type
             when "yaml", "yml"
               YAML.parse(raw).as_h
             when "json"
               JSON.parse(raw).as_h
             end

      return unless data

      data.each do |key, value|
        @config[key.to_s.downcase] = Any.new(value)
      end
    end

    def write
      if file = @config_file
        raise Error.new("Config file is empty") if file.empty?

        write(file, true)
      end

      raise Error.new("Config file is not be setted")
    end

    def write(file : String, force : Bool = false)
      @logger.info("Attempting to write configuration to file: #{file}")

      unless extname = Utils.config_type(file)
        raise "Requires vaild extension name with file: #{file}"
      end

      unless SUPPORTED_EXTS.includes?(extname)
        raise UnsupportedConfigError.new(file)
      end

      mode = "w"
      if !force && File.exists?(file)
        raise "File #{file} exists. Use write_config(force: true) to overwrite"
      end

      File.open(file, mode) do |f|
        case extname
        when "yaml", "yml"
          f.puts raw.to_yaml
        when "json"
          f.puts raw.to_json
        end
      end
    end

    # def set_env(key : String, value : String)
    #   @env[env_key(key)] = value
    # end

    # def get_env(key : String) : String
    #   ENV[key]? || ENV[env_key(key)]? || @env[env_key(key)]
    # end

    # def get_env?(key : String) : String?
    #   new_key = env_key(key)
    #   if ENV.has_key?(key)
    #     ENV[key]
    #   elsif ENV.has_key?(new_key)
    #     ENV[new_key]
    #   elsif @env.has_key?(new_key)
    #     @env[new_key]
    #   end
    # end

    # def env_prefix=(prefix : String)
    #   @env_prefix = prefix.upcase
    # end

    def debugging=(value : Bool)
      @logger.level = value ? Logger::DEBUG : Logger::ERROR
      @logging = value
    end

    # :nodoc:
    def to_json(json)
      raw.to_json(json)
    end

    # :nodoc:
    def to_yaml(yaml)
      raw.to_yaml(yaml)
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
      @logger.debug("Checking for #{file}")
      if File.exists?(file) && File.readable?(file)
        @logger.debug("Found: #{file}")
        file
      end
    end

    private def alias?(key)
      @aliases.has_key?(key)
    end

    private def alias_key(key : String)
      @aliases[key]? ? @aliases[key] : key
    end

    private def merge_env_key(key : String)
      if (prefix = @env_prefix) && !prefix.empty?
        "#{prefix}_#{key}"
      else
        key
      end
    end

    private def raw
      @defaults.merge(@config)
    end

    private def env_key(key : String)
      key.sub(/^[A-Z]/) { |char| char.downcase }
        .gsub(/[A-Z]/) { |char| "_#{char}" }
        .upcase
    end

    private def default_logger_formatter
      Logger::Formatter.new do |severity, datetime, progname, message, io|
        io << severity << " " << datetime.to_s("%F %T") << " " << message
      end
    end
  end
end
