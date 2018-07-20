require "../spec_helper"

private struct Profile
  property name
  property hobbies
  property age
  property eyes

  def initialize(@name : String, @hobbies : Array(String), @age : Int32, @eyes : String)
  end
end

private struct JSONProfile
  include JSON::Serializable

  property name : String
  property hobbies : Array(String)
  property age : Int32
  property eyes : String
end

private struct YAMLProfile
  include YAML::Serializable

  property name : String
  property hobbies : Array(String)
  property age : Int32
  property eyes : String
end

private struct JSONClothes
  include JSON::Serializable

  property jacket : String
  property trousers : String
  property pants : Hash(String, String)
end

private struct YAMLClothes
  include JSON::Serializable

  property jacket : String
  property trousers : String
  property pants : Hash(String, String)
end

private struct Clothes
  property jacket
  property trousers
  property pants

  def initialize(@jacket : String, @pants : Hash(String, String), @trousers : String)
  end
end

describe Totem::Config do
  describe ".parse" do
    it "of json" do
      t = Totem::Config.parse json_raw, "json"
      json_spec_group t
    end

    it "of yaml" do
      t = Totem::Config.parse yaml_raw, "yaml"
      yaml_spec_group t
    end

    it "of env" do
      t = Totem::Config.parse env_raw, "env"
      env_spec_group t
    end
  end

  describe ".from_file" do
    describe "use json file" do
      it "without paths" do
        t = Totem::Config.from_file File.join(fixture_path, "config.json")
        json_spec_group t
      end

      it "with paths" do
        t = Totem::Config.from_file "config.json", [".", "~/", fixture_path]
        json_spec_group t
      end
    end

    it "use yaml file" do
      it "without paths" do
        t = Totem::Config.from_file File.join(fixture_path, "config.yaml")
        yaml_spec_group t
      end

      it "with paths" do
        t = Totem::Config.from_file "config.yaml", [".", fixture_path, "~/"]
        yaml_spec_group t
      end
    end

    it "use env file" do
      it "without paths" do
        t = Totem::Config.from_file File.join(fixture_path, "sample.env")
        env_spec_group t
      end

      it "with paths" do
        t = Totem::Config.from_file "sample.env", [".", fixture_path, "~/"]
        env_spec_group t
      end
    end
  end

  describe "#new" do
    it "should works as Totem::Config" do
      t = Totem::Config.new
      t.set_default "name", "foo"
      t.get("name").as_s.should eq "foo"

      t.set("name", "bar")
      t.alias(alias_key: "key", key: "name")
      t.get("name").as_s.should eq "bar"
      t.get("key").as_s.should eq "bar"
    end
  end

  describe "#get" do
    describe "find key" do
      it "should gets" do
        t = Totem::Config.from_file File.join(fixture_path, "config.json")
        t.get("name").should eq Totem::Any.new("Cake")
        t.get("name").raw.should eq t.get("name").as_s

        expect_raises Totem::NotFoundConfigKeyError do
          t.get("unkown")
        end
      end
    end

    describe "find nested key" do
      it "should gets" do
        t = Totem::Config.new
        t.set_default("super", {
          "deep" => {
            "nested" => "value",
          },
        })

        t.get("super").as_h.should eq({"deep" => Totem::Any.new({"nested" => "value"})})
        t.get("super.deep").as_h.should eq({"nested" => Totem::Any.new("value")})
        t.get("super.deep.nested").as_s.should eq("value")

        expect_raises Totem::NotFoundConfigKeyError do
          t.get("unkown.super.deep.nested")
        end
      end

      it "returns nil with shadowed path" do
        pending do
          "todo"
        end
      end
    end
  end

  describe "#[]" do
    it "should gets" do
      t = Totem::Config.from_file File.join(fixture_path, "config.json")
      t["name"].should eq Totem::Any.new("Cake")
      t["name"].raw.should eq t["name"].as_s

      expect_raises Totem::NotFoundConfigKeyError do
        t["unkown"]
      end
    end
  end

  describe "#[]?" do
    it "should gets" do
      t = Totem::Config.from_file File.join(fixture_path, "config.json")
      t["name"]?.not_nil!.should eq Totem::Any.new("Cake")
      t["name"]?.not_nil!.raw.should eq t["name"]?.not_nil!.as_s
      t["unkown"]?.should be_nil

      t.set("super.deep.nested.key", "value")
      t.["super"]?.not_nil!.raw.should be_a Hash(String, Totem::Any)
      t.["super.deep.nested.key"]?.not_nil!.raw.should eq "value"
      t.["super.deep.nested.key.subkey"]?.should be_nil
    end
  end

  describe "#fetch" do
    it "should gets" do
      t = Totem::Config.from_file File.join(fixture_path, "config.json")
      t.fetch("name").not_nil!.as_s.should eq "Cake"
      t.fetch("unkown").should be_nil
      t.fetch("unkown-str", "fetch").not_nil!.as_s.should eq "fetch"
      t.fetch("unkown-number", 123).not_nil!.as_i.should eq 123
      t.fetch("unkown-bool", true).not_nil!.as_bool.should be_true

      t.set("super.deep.nested.key", "value")
      t.fetch("super").not_nil!.raw.should be_a Hash(String, Totem::Any)
      t.fetch("super.deep.nested.key").not_nil!.raw.should eq "value"
      t.fetch("super.deep.nested.key.subkey", "foo").not_nil!.raw.should eq "foo"
      t.fetch("super.deep.nested.key.subkey").should be_nil
    end
  end

  describe "#set" do
    it "should sets" do
      t = Totem::Config.new
      t.set("str", "foo")
      t.set("int", 123)
      t.set("float", 123.45)
      t.set("bool", true)
      t.set("array", [1, "2", 3])
      t.set("hash", {"a" => "b", "c" => "d"})
      t.set("json_any", JSON.parse(%Q{{"a": "b", "c": "d"}}))
      t.set("yaml_any", YAML.parse(%Q{---\na: b\nc: d}))
      t.set("super.deep.nested.key", "value")

      t.get("str").raw.should eq "foo"
      t.get("int").raw.should eq 123
      t.get("float").raw.should eq 123.45
      t.get("bool").raw.should be_true
      t.get("array").raw.should eq [Totem::Any.new(1), Totem::Any.new("2"), Totem::Any.new(3)]
      t.get("hash").raw.should eq({"a" => Totem::Any.new("b"), "c" => Totem::Any.new("d")})
      t.get("json_any").raw.should eq JSON.parse(%Q{{"a": "b", "c": "d"}})
      t.get("yaml_any").raw.should eq YAML.parse(%Q{---\na: b\nc: d})
      t.get("super.deep.nested").raw.should eq({"key" => Totem::Any.new("value")})
      t.get("super.deep.nested.key").raw.should eq "value"
    end
  end

  describe "#[]=" do
    it "should sets" do
      t = Totem::Config.new
      t["str"] = "foo"
      t["int"] = 123
      t["float"] = 123.45
      t["bool"] = true
      t["array"] = [1, "2", 3]
      t["hash"] = {"a" => "b", "c" => "d"}
      t["json_any"] = JSON.parse(%Q{{"a": "b", "c": "d"}})
      t["yaml_any"] = YAML.parse(%Q{---\na: b\nc: d})
      t["super.deep.nested.key"] = "value"

      t.get("str").raw.should eq "foo"
      t.get("int").raw.should eq 123
      t.get("float").raw.should eq 123.45
      t.get("bool").raw.should be_true
      t.get("array").raw.should eq [Totem::Any.new(1), Totem::Any.new("2"), Totem::Any.new(3)]
      t.get("hash").raw.should eq({"a" => Totem::Any.new("b"), "c" => Totem::Any.new("d")})
      t.get("json_any").raw.should eq JSON.parse(%Q{{"a": "b", "c": "d"}})
      t.get("yaml_any").raw.should eq YAML.parse(%Q{---\na: b\nc: d})
      t.get("super.deep.nested").raw.should eq({"key" => Totem::Any.new("value")})
      t.get("super.deep.nested.key").raw.should eq "value"
    end
  end

  describe "#has_key?" do
    it "should works" do
      t = Totem::Config.from_file File.join(fixture_path, "config.json")
      t.has_key?("name").should be_true
      t.has_key?("unkown").should be_false

      t.set("super.deep.nested.key", "value")
      t.has_key?("super").should be_true
      t.has_key?("super.deep").should be_true
      t.has_key?("super.deep.nested").should be_true
      t.has_key?("super.deep.nested.key").should be_true
      t.has_key?("super.deep.nested.key.subkey").should be_false
    end
  end

  describe "#mapping" do
    it "should works with JSON::Serializable" do
      t = Totem::Config.parse yaml_raw, "yaml"
      profile = t.mapping(JSONProfile)
      profile.name.should eq "steve"
      profile.age.should eq 35
      profile.eyes.should eq "brown"
      profile.hobbies.should be_a Array(String)
      profile.hobbies.size.should eq 3
      profile.hobbies[0].should eq "skateboarding"
    end

    it "should works with YAML::Serializable" do
      t = Totem::Config.parse yaml_raw, "yaml"
      profile = t.mapping(YAMLProfile)
      profile.name.should eq "steve"
      profile.age.should eq 35
      profile.eyes.should eq "brown"
      profile.hobbies.should be_a Array(String)
      profile.hobbies.size.should eq 3
      profile.hobbies[0].should eq "skateboarding"
    end

    it "throws an exception without JSON::Serializable" do
      t = Totem::Config.parse yaml_raw, "yaml"
      expect_raises Totem::MappingError do
        t.mapping(Profile)
      end
    end
  end

  describe "#mapping(key)" do
    it "should works with JSON::Serializable" do
      t = Totem::Config.parse yaml_raw, "yaml"
      clothes = t.mapping(JSONClothes, "clothing")
      clothes.jacket.should eq "leather"
    end

    it "should works with YAML::Serializable" do
      t = Totem::Config.parse yaml_raw, "yaml"
      clothes = t.mapping(YAMLClothes, "clothing")
      clothes.jacket.should eq "leather"
    end

    it "throws an exception without JSON::Serializable" do
      t = Totem::Config.parse yaml_raw, "yaml"
      expect_raises Totem::MappingError do
        t.mapping(Clothes, "clothing")
      end
    end
  end
end
