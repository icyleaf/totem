require "./spec_helper"

private def json_spec_group(t)
  t.get("name").as_s.should eq "Cake"
  t.get("gluten_free").as_bool.should be_false
  t.get("duty_free").as_bool(strict: false).should be_false
  t.get("ppu").as_f.should eq 0.55
  t.get("batters").as_h["batter"].as_a[0].as_h["type"].as_s.should eq "Regular"
end

private def yaml_spec_group(t)
  t.get("hacker").as_bool.should be_true
  t.get("gender").as_bool(strict: false).should be_true
  t.get("age").as_i.should eq 35
  t.get("clothing").as_h["pants"].as_h["size"].as_s.should eq "large"
end

private def env_spec_group(t)
  t.get("blank").as_s.empty?.should be_true
  t.get("str").as_s.should eq "foo"
  t.get("STR_with_comments").as_s.should eq "bar"
  t.get("STR_with_hash_symbol").as_s.should eq "abc#123"
  t.get("int").as_i.should eq 42
  t.get("float").as_f.should eq 33.3
  t.get("BOOL_TRUE").as_i.should eq 1
  t.get("BOOL_FALSE").as_i.should eq 0
  t.get("BOOL_TRUE").as_bool?.should be_nil
  t.get("BOOL_TRUE").as_bool(strict: false).should be_true
  t.get("BOOL_FALSE").as_bool?.should be_nil
  t.get("BOOL_FALSE").as_bool(strict: false).should be_false
end

describe Totem do
  describe "#new" do
    it "should works as Totem::Config" do
      t =  Totem.new
      t.set_default "name", "foo"
      t.get("name").as_s.should eq "foo"

      t.set("name", "bar")
      t.alias(alias_key: "key", key: "name")
      t.get("name").as_s.should eq "bar"
      t.get("key").as_s.should eq "bar"
    end
  end

  describe "#parse" do
    it "of json" do
      t = Totem.parse json_raw, "json"
      json_spec_group t
    end

    it "of yaml" do
      t = Totem.parse yaml_raw, "yaml"
      yaml_spec_group t
    end

    it "of env" do
      t = Totem.parse env_raw, "env"
      env_spec_group t
    end
  end

  describe "#from_yaml" do
    it "should parse" do
      t = Totem.from_yaml yaml_raw
      yaml_spec_group t
    end
  end

  describe "#from_json" do
    it "should parse" do
      t = Totem.from_json json_raw
      json_spec_group t
    end
  end

  describe "#from_env" do
    it "should parse" do
      t = Totem.from_env env_raw
      env_spec_group t
    end
  end

  describe "#from_file" do
    describe "use json file" do
      it "without paths" do
        file = File.join(fixture_path, "config.json")
        t = Totem.from_file file
        json_spec_group t
      end

      it "with paths" do
        t = Totem.from_file "config.json", [".", "~/", fixture_path]
        json_spec_group t
      end
    end

    it "use yaml file" do
      it "without paths" do
        file = File.join(fixture_path, "config.yaml")
        t = Totem.from_file file
        yaml_spec_group t
      end

      it "with paths" do
        t = Totem.from_file "config.yaml", [".", fixture_path, "~/"]
        yaml_spec_group t
      end
    end

    it "use env file" do
      it "without paths" do
        file = File.join(fixture_path, "sample.yaml")
        t = Totem.from_file file
        env_spec_group t
      end

      it "with paths" do
        t = Totem.from_file "sample.yaml", [".", fixture_path, "~/"]
        env_spec_group t
      end
    end
  end
end
