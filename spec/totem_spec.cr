require "./spec_helper"

private def json_raw
  load_fixture("config.json")
end

private def yaml_raw
  load_fixture("config.yaml")
end

private def config_files
  ["config.json", "config.yaml"]
end

describe Totem do
  describe "#new" do
    it "should works as Totem::Reader" do
      r = Totem.new
      r.set_default "name", "foo"
      r.get("name").as_s.should eq "foo"

      r.set("name", "bar")
      r.register_alias(alias_key: "key", key: "name")
      r.get("name").as_s.should eq "bar"
      r.get("key").as_s.should eq "bar"
    end
  end

  describe "#from_yaml" do
    it "should parse" do
      r = Totem.from_yaml yaml_raw
      r.get("Hacker").as_bool.should be_true
      r.get("age").as_i.should eq 35
      r.get("clothing").as_h["pants"].as_h["size"].as_s.should eq "large"
    end
  end

  describe "#parse" do
    it "of json" do
      r = Totem.parse json_raw, "json"
      r.get("name").as_s.should eq "Cake"
      r.get("ppu").as_f.should eq 0.55
      r.get("batters").as_h["batter"].as_a[0].as_h["type"].as_s.should eq "Regular"
    end

    it "of yaml" do
      r = Totem.parse yaml_raw, "yaml"
      r.get("Hacker").as_bool.should be_true
      r.get("age").as_i.should eq 35
      r.get("clothing").as_h["pants"].as_h["size"].as_s.should eq "large"
    end
  end

  describe "#from_file" do
    describe "use json file" do
      it "without paths" do
        file = File.join(fixture_path, "config.json")
        r = Totem.from_file file

        r.get("name").as_s.should eq "Cake"
        r.get("ppu").as_f.should eq 0.55
        r.get("batters").as_h["batter"].as_a[0].as_h["type"].as_s.should eq "Regular"
      end

      it "with paths" do
        r = Totem.from_file "config.json", [".", "~/", fixture_path]

        r.get("name").as_s.should eq "Cake"
        r.get("ppu").as_f.should eq 0.55
        r.get("batters").as_h["batter"].as_a[0].as_h["type"].as_s.should eq "Regular"
      end
    end

    it "use yaml file" do
      it "without paths" do
        file = File.join(fixture_path, "config.yaml")
        r = Totem.from_file file
        r.get("Hacker").as_bool.should be_true
        r.get("age").as_i.should eq 35
        r.get("clothing").as_h["pants"].as_h["size"].as_s.should eq "large"
      end

      it "with paths" do
        r = Totem.from_file "config.yaml", [".", fixture_path, "~/"]
        r.get("Hacker").as_bool.should be_true
        r.get("age").as_i.should eq 35
        r.get("clothing").as_h["pants"].as_h["size"].as_s.should eq "large"
      end
    end
  end
end
