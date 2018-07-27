require "./totem/ext/*"
require "./totem/*"

module Totem
  def self.new(config_name = "config", config_type : String? = nil, config_paths : Array(String) = [] of String)
    Config.new(config_name, config_type, config_paths)
  end

  def self.from_file(file : String, paths : Array(String)? = nil)
    Config.from_file(file, paths)
  end

  def self.parse(raw : String, type : String)
    Config.parse(raw, type)
  end

  def self.from_json(raw : String)
    Config.parse(raw, "json")
  end

  def self.from_yaml(raw : String)
    Config.parse(raw, "yaml")
  end

  def self.from_env(raw : String)
    Config.parse(raw, "env")
  end
end
