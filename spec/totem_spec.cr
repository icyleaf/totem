require "./spec_helper"

describe Totem do
  describe ".parse" do
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

  describe ".from_yaml" do
    it "should parse" do
      t = Totem.from_yaml yaml_raw
      yaml_spec_group t
    end
  end

  describe ".from_json" do
    it "should parse" do
      t = Totem.from_json json_raw
      json_spec_group t
    end
  end

  describe ".from_env" do
    it "should parse" do
      t = Totem.from_env env_raw
      env_spec_group t
    end
  end

  describe ".from_file" do
    describe "use json file" do
      it "should works without paths" do
        t = Totem.from_file File.join(fixture_path, "config.json")
        json_spec_group t
      end

      it "should works with paths" do
        t = Totem.from_file "config.json", [".", "~/", fixture_path]
        json_spec_group t
      end
    end

    describe "use yaml file" do
      it "should works without paths" do
        t = Totem.from_file File.join(fixture_path, "config.yaml")
        yaml_spec_group t
      end

      it "should works with paths" do
        t = Totem.from_file "config.yaml", [".", fixture_path, "~/"]
        yaml_spec_group t
      end
    end

    describe "use env file" do
      it "should works without paths" do
        t = Totem.from_file File.join(fixture_path, "config.env")
        env_spec_group t
      end

      it "should works with paths" do
        t = Totem.from_file "config.env", [".", fixture_path, "~/"]
        env_spec_group t
      end
    end

    describe "use environment" do
      it "should works" do
        t = Totem.from_file "config.yaml", [File.join(fixture_path, "envs")], "development"
        t.get("host").should eq "localhost"
        t.get("port").should eq 3306
        t.get("database").should eq "totem_development"
      end
    end
  end

  describe "#new" do
    it "should works as Totem::Config" do
      t = Totem.new
      t.set_default "name", "foo"
      t.get("name").as_s.should eq "foo"

      t.set("name", "bar")
      t.alias(alias_key: "key", key: "name")
      t.get("name").as_s.should eq "bar"
      t.get("key").as_s.should eq "bar"
    end
  end

  # More to see config_spec.cr
end
