require "./spec_helper"

private def json_raw
  load_fixture("config.json")
end

private def yaml_raw
  load_fixture("config.yaml")
end

private def env_raw
  load_fixture("sample.env")
end

private def json_spec_group(r)
  r.get("name").as_s.should eq "Cake"
  r.get("gluten_free").as_bool.should be_false
  r.get("duty_free").as_bool(strict: false).should be_false
  r.get("ppu").as_f.should eq 0.55
  r.get("batters").as_h["batter"].as_a[0].as_h["type"].as_s.should eq "Regular"
end

private def yaml_spec_group(r)
  r.get("hacker").as_bool.should be_true
  r.get("gender").as_bool(strict: false).should be_true
  r.get("age").as_i.should eq 35
  r.get("clothing").as_h["pants"].as_h["size"].as_s.should eq "large"
end

private def env_spec_group(r)
  r.get("blank").as_s.empty?.should be_true
  r.get("str").as_s.should eq "foo"
  r.get("STR_with_comments").as_s.should eq "bar"
  r.get("STR_with_hash_symbol").as_s.should eq "abc#123"
  r.get("int").as_i.should eq 42
  r.get("float").as_f.should eq 33.3
  r.get("BOOL_TRUE").as_i.should eq 1
  r.get("BOOL_FALSE").as_i.should eq 0
  r.get("BOOL_TRUE").as_bool?.should be_nil
  r.get("BOOL_TRUE").as_bool(strict: false).should be_true
  r.get("BOOL_FALSE").as_bool?.should be_nil
  r.get("BOOL_FALSE").as_bool(strict: false).should be_false
end

describe Totem do
  describe "#new" do
    it "should works as Totem::Reader" do
      r = Totem.new
      r.set_default "name", "foo"
      r.get("name").as_s.should eq "foo"

      r.set("name", "bar")
      r.alias(alias_key: "key", key: "name")
      r.get("name").as_s.should eq "bar"
      r.get("key").as_s.should eq "bar"
    end
  end

  describe "#parse" do
    it "of json" do
      r = Totem.parse json_raw, "json"
      json_spec_group r
    end

    it "of yaml" do
      r = Totem.parse yaml_raw, "yaml"
      yaml_spec_group r
    end

    it "of env" do
      r = Totem.parse env_raw, "env"
      env_spec_group r
    end
  end

  describe "#from_yaml" do
    it "should parse" do
      r = Totem.from_yaml yaml_raw
      yaml_spec_group r
    end
  end

  describe "#from_json" do
    it "should parse" do
      r = Totem.from_json json_raw
      json_spec_group r
    end
  end

  describe "#from_env" do
    it "should parse" do
      r = Totem.from_env env_raw
      env_spec_group r
    end
  end

  describe "#from_file" do
    describe "use json file" do
      it "without paths" do
        file = File.join(fixture_path, "config.json")
        r = Totem.from_file file
        json_spec_group r
      end

      it "with paths" do
        r = Totem.from_file "config.json", [".", "~/", fixture_path]
        json_spec_group r
      end
    end

    it "use yaml file" do
      it "without paths" do
        file = File.join(fixture_path, "config.yaml")
        r = Totem.from_file file
        yaml_spec_group r
      end

      it "with paths" do
        r = Totem.from_file "config.yaml", [".", fixture_path, "~/"]
        yaml_spec_group r
      end
    end

    it "use env file" do
      it "without paths" do
        file = File.join(fixture_path, "sample.yaml")
        r = Totem.from_file file
        env_spec_group r
      end

      it "with paths" do
        r = Totem.from_file "sample.yaml", [".", fixture_path, "~/"]
        env_spec_group r
      end
    end
  end
end
