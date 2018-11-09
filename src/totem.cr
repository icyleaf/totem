require "./totem/*"

module Totem
  def self.new(config_name = "config", config_type : String? = nil,
               config_paths : Array(String) = [] of String,
               config_env : String? = nil, config_envs = Config::CONFIG_ENVS,
               key_delimiter : String? = Config::KEY_DELIMITER)
    Config.new(config_name, config_type, config_paths, config_env, config_envs, key_delimiter: key_delimiter)
  end

  def self.from_file(file : String, paths : Array(String)? = nil,
                     environment : String? = nil, key_delimiter : String = Config::KEY_DELIMITER)
    Config.from_file(file, paths, environment, key_delimiter)
  end

  def self.parse(raw : String, type : String, key_delimiter : String = Config::KEY_DELIMITER)
    Config.parse(raw, type, key_delimiter)
  end

  def self.from_json(raw : String, key_delimiter : String = Config::KEY_DELIMITER)
    parse(raw, "json", key_delimiter)
  end

  def self.from_yaml(raw : String, key_delimiter : String = Config::KEY_DELIMITER)
    parse(raw, "yaml", key_delimiter)
  end

  def self.from_env(raw : String, key_delimiter : String = Config::KEY_DELIMITER)
    parse(raw, "env", key_delimiter)
  end
end
