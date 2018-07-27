require "spec"
require "tempfile"
require "file_utils"
require "../src/totem"
require "../src/totem/config_types/*"

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
  t.get("name").as_s.should eq "Cake"
  t.get("gluten_free").as_bool.should be_false
  t.get("duty_free").as_bool.should be_false
  t.get("ppu").as_f.should eq 0.55
  t.get("batters").as_h["batter"].as_a[0].as_h["type"].as_s.should eq "Regular"
end

def yaml_spec_group(t)
  t.get("hacker").as_bool.should be_true
  t.get("gender").as_bool.should be_true
  t.get("age").as_i.should eq 35
  t.get("clothing").as_h["pants"].as_h["size"].as_s.should eq "large"
end

def env_spec_group(t)
  t.get("blank").as_s.empty?.should be_true
  t.get("str").as_s.should eq "foo"
  t.get("STR_with_comments").as_s.should eq "bar"
  t.get("STR_with_hash_symbol").as_s.should eq "abc#123"
  t.get("int").as_i.should eq 42
  t.get("float").as_f.should eq 33.3
  t.get("BOOL_TRUE").as_i.should eq 1
  t.get("BOOL_FALSE").as_i.should eq 0
  t.get("BOOL_TRUE").as_bool.should be_true
  t.get("BOOL_FALSE").as_bool.should be_false
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
