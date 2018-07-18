require "./totem/**"

module Totem
  @@instance = Reader.new

  def self.shards
    @@instance
  end

  def self.new(config_name = "config", config_type : String? = nil, config_paths : Array(String) = [] of String)
    Reader.new(config_name, config_type, config_paths)
  end

  def self.from_file(file : String, paths : Array(String)? = nil)
    Reader.from_file(file, paths)
  end

  def self.parse(raw : String, type : String)
    Reader.parse(raw, type)
  end

  def self.from_json(raw : String)
    Reader.parse(raw, "json")
  end

  def self.from_yaml(raw : String)
    Reader.parse(raw, "yaml")
  end

  def self.from_env(raw : String)
    Reader.parse(raw, "env")
  end
end
