require "spec"
require "tempfile"
require "file_utils"
require "../src/totem"
require "../src/totem/config_types/*"
require "../src/totem/remote_providers/*"

def fixture_path
  path = File.expand_path("../fixtures/", __FILE__)
end

def load_fixture(filename : String)
  File.read_lines(File.join(fixture_path, filename)).join("\n")
end

def json_raw
  load_fixture("config.json")
end

def yaml_raw
  load_fixture("config.yaml")
end

def env_raw
  load_fixture("config.env")
end

def json_spec_group(t)
  t.get("name").should eq "Cake"
  t.get("gluten_free").as_bool.should be_false
  t.get("duty_free").as_bool.should be_false
  t.get("ppu").should eq 0.55
  t.get("batters").as_h["batter"].as_a[0].as_h["type"].as_s.should eq "Regular"
end

def yaml_spec_group(t)
  t.get("hacker").as_bool.should be_true
  t.get("gender").as_bool.should be_true
  t.get("age").should eq 35
  t.get("clothing").as_h["pants"].as_h["size"].as_s.should eq "large"
end

def env_spec_group(t)
  t.get("totem_env").should eq "production"
  t.get("totem_api_key").should eq "ae89a283-9b0c-4417-af13-c8b99921c5ac"
  t.get("totem_admin_email").should eq "foobar@example.com"
  t.get("totem_admin_username").should eq "foobar"
  t.get("mysql_host").should eq "localhost"
  t.get("mysql_port").as_i.should eq 3306
  t.get("mysql_db").should eq "totem"
  t.get("mysql_user").should eq "totem"
  t.get("mysql_password").should eq "$wrwYAH3gQ"
end

SPEC_TEMPFILE_PATH = File.join(Tempfile.dirname, "totem-spec-#{Random.new.hex(8)}")

def with_tempfile(*paths, file = __FILE__)
  calling_spec = File.basename(file).rchop("_spec.cr")
  paths = paths.map { |path| File.join(SPEC_TEMPFILE_PATH, calling_spec, path) }
  FileUtils.mkdir_p(File.join(SPEC_TEMPFILE_PATH, calling_spec))

  begin
    yield *paths
  ensure
    paths.each do |path|
      FileUtils.rm_r(path) if File.exists?(path)
    end
  end
end
