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

private def with_env(vars : Hash(String, String))
  # Writing env variables
  vars.each do |key, value|
    ENV[key.upcase] = value
  end

  yield

  # Clean up
  vars.keys.each do |key|
    ENV.delete(key.upcase)
  end
end

private def with_redis
  endpoint = "redis://localhost:6379/0"
  client = Redis.new(url: endpoint)
  client.set("name", "foo")
  client.set("config_development.json", json_raw)
  client.set("config_development", json_raw)

  yield endpoint

  client.del("name")
  client.del("config_development.json")
  client.del("config_development")
end

private def with_etcd
  endpoint = "localhost:2379"
  client = Etcd.client(endpoint)
  client.set("/name", {:value => "foo"})
  client.set("/config/development.json", {:value => json_raw})
  client.set("/config/development", {:value => json_raw})

  yield endpoint

  client.delete("/name")
  client.delete("/config/development.json")
  client.delete("/config/development")
end

describe Totem::Config do
  describe "methods" do
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
          t = Totem::Config.from_file File.join(fixture_path, "config.env")
          env_spec_group t
        end

        it "with paths" do
          t = Totem::Config.from_file "config.env", [".", fixture_path, "~/"]
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

    describe "#flat_keys" do
      it "should iterates" do
        t = Totem::Config.new
        t.set_default("user.name", "foo")
        t.set_default("user.age", 35)
        t.alias("age", "user.age")
        t.set("id", 12345)

        t.flat_keys.should eq ["age", "id", "user.name", "user.age"]
      end
    end

    describe "#settings" do
      it "should gets" do
        hash = {
          "name" => "elian",
          "age"  => 20,
        }

        ENV["TOTEM_AGE"] = "40"

        t = Totem::Config.parse hash.to_yaml, "yaml"
        t.set_default("name", "foo")
        t.set_default("age", 35)
        t.alias("age", "name")

        t.env_prefix = "totem"
        t.bind_env("TOTEM_AGE")
        t.set("name", "bar")

        t.settings["name"].raw.should eq "bar"
        t.settings["age"].raw.should eq "bar"
      end
    end

    describe "#keys" do
      it "should iterates" do
        hash = {
          "name" => "elian",
          "age"  => 20,
        }

        t = Totem::Config.parse hash.to_yaml, "yaml"
        t.set_default("name", "foo")
        t.set_default("age", 35)
        t.alias("age", "name")
        t.set("name", "bar")

        t.keys.each do |key|
          hash.has_key?(key).should be_true
        end
      end
    end

    describe "#each" do
      it "should iterates" do
        hash = {
          "name" => "elian",
          "age"  => 20,
        }

        t = Totem::Config.parse hash.to_yaml, "yaml"
        t.set_default("name", "foo")
        t.set_default("age", 35)
        t.set("name", "bar")

        hash["name"] = "bar"

        t.each do |key, value|
          hash[key].should eq value.raw
        end
      end
    end

    describe "#set_default" do
      it "should sets" do
        t = Totem::Config.new
        t.set_default("str", "foo")
        t.set_default("int", 123)
        t.set_default("float", 123.45)
        t.set_default("bool", true)
        t.set_default("array", [1, "2", 3])
        t.set_default("hash", {"a" => "b", "c" => "d"})
        t.set_default("json_any", JSON.parse(%Q{{"a": "b", "c": "d"}}))
        t.set_default("yaml_any", YAML.parse(%Q{---\na: b\nc: d}))
        t.set_default("super.deep.nested.key", "value")

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

    describe "#set_defaults" do
      it "should sets with hash" do
        t = Totem::Config.new
        t.set_defaults({"str" => "foo", "int" => 123, "array" => [1, "2", 3], "hash" => {"a" => "b", "c" => "d"}})

        t.get("str").raw.should eq "foo"
        t.get("int").raw.should eq 123
        t.get("array").raw.should eq [Totem::Any.new(1), Totem::Any.new("2"), Totem::Any.new(3)]
        t.get("hash").raw.should eq({"a" => Totem::Any.new("b"), "c" => Totem::Any.new("d")})
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

    describe "#bind_env" do
      it "should gets without env prefix" do
        with_env({
          "TOTEM_NAME"                  => "foo",
          "TOTEM_SUPER_DEEP_NESTED_KEY" => "value",
        }) do
          t = Totem::Config.new
          t.bind_env("TOTEM_NAME")
          t.bind_env("key", "TOTEM_SUPER_DEEP_NESTED_KEY")

          t.get("totem_name").raw.should eq "foo"
          t.get("key").raw.should eq "value"
        end
      end

      it "should gets with env prefix" do
        with_env({
          "TOTEM_NAME"                  => "foo",
          "TOTEM_SUPER_DEEP_NESTED_KEY" => "value",
        }) do
          t = Totem::Config.new
          t.env_prefix = "totem"
          t.bind_env("name")
          t.bind_env("super.deep.nested.key", "TOTEM_SUPER_DEEP_NESTED_KEY")

          t.get("name").raw.should eq "foo"
          t.get("SUPER.deep.nested.key").raw.should eq "value"
        end
      end
    end

    describe "#automatic_env" do
      it "should gets without env prefix" do
        with_env({
          "TOTEM_NAME"                  => "foo",
          "TOTEM_SUPER_DEEP_NESTED_KEY" => "value",
        }) do
          t = Totem::Config.new
          t.automatic_env

          t.get("totem_NAME").raw.should eq "foo"
          t.get("TOTEM_super_Deep_nESTed_kEy").raw.should eq "value"
        end
      end

      it "should gets with env prefix" do
        with_env({
          "TOTEM_NAME"                  => "foo",
          "TOTEM_SUPER_DEEP_NESTED_KEY" => "value",
        }) do
          t = Totem::Config.new
          t.automatic_env("totem")

          t.get("name").raw.should eq "foo"
          t.get("super_Deep_nESTed_kEy").raw.should eq "value"
        end
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

      it "throws an exception without JSON::Serializable or YAML::Serializable" do
        t = Totem::Config.parse yaml_raw, "yaml"
        expect_raises Totem::MappingError do
          t.mapping(Profile)
        end
      end

      it "throws an exception if key is not exists" do
        t = Totem::Config.parse yaml_raw, "yaml"
        expect_raises Totem::MappingError do
          t.mapping(YAMLProfile, "null")
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

    describe "#store_file!" do
      it "should writes to json file" do
        with_tempfile("config.json") do |file|
          t = Totem::Config.parse json_raw, "json"
          t.store_file!(file)

          ::JSON.parse(File.read(file)).as_h.each do |key, value|
            t[key].should eq value.raw
          end
        end
      end

      it "should writes to yaml file" do
        with_tempfile("config.yaml") do |file|
          t = Totem::Config.parse yaml_raw, "yaml"
          t.store_file!(file)

          data = ::YAML.parse(File.read(file)).as_h
          data.each do |key, value|
            t[key.to_s].should eq value.raw
          end
        end
      end

      it "should writes to env file" do
        with_tempfile("config.env") do |file|
          t = Totem::Config.parse env_raw, "env"
          t.store_file!(file)

          Poncho.parse(file).each do |key, value|
            t[key].should eq value
          end
        end
      end
    end
  end

  describe "following order" do
    it "should get right value" do
      # - alias
      # - override, explicit call to `set`
      # - env
      # - config
      # - default
      t = Totem::Config.parse %Q{---\nid: 1\nname: Dasia\nsuper:\n  deep:\n    nested:\n      key: "value"}, "yaml"

      # Default
      t.set_default("id", 123)
      t.set_default("name", "Guest")
      t.set_default("super.deep.nested.key", "foo")
      t.set_default("super.deep.nested.name", "apple")

      # Config
      t.get("id").raw.should eq 1
      t.get("name").raw.should eq "Dasia"
      t.get("super.deep.nested.key").raw.should eq "value"
      t.get("super.deep.nested.name").raw.should eq "apple"

      # Env
      ENV["TOTEM_ID"] = "123"
      ENV["TOTEM_NAME"] = "Melany"
      ENV["TOTEM_SUPER_DEEP_NESTED_KEY"] = "bar"
      t.bind_env("name", "TOTEM_NAME")
      t.get("name").raw.should eq "Melany"

      t.env_prefix = "totem"
      t.bind_env("ID")
      t.get("id").raw.should eq "123"
      t.automatic_env
      t.get("super_deep_nested_key").raw.should eq "bar"
      t.get("super.deep.nested.name").raw.should eq "apple"

      # override
      t.set("id", 321)
      t.set("name", "Katrina")
      t.set("super.deep.nested.key", "bar")

      t.get("id").raw.should eq 321
      t.get("name").raw.should eq "Katrina"
      t.get("super.deep.nested.key").raw.should eq "bar"
      t.get("super.deep.nested.name").raw.should eq "apple"

      # alias
      t.alias("no", "id")
      t.alias("name", "super.deep.nested.key")
      t.get("no").raw.should eq 321
      t.get("name").raw.should eq "bar"
      t.get("super.deep.nested.name").raw.should eq "apple"
    end
  end

  describe "custom key delimiter" do
    it "should getts by set nested key" do
      t = Totem::Config.new(key_delimiter: "_")

      t.set("profile_user_name", "foo")
      t.set("profile_user_age", 20)

      t.get("profile_user_name").should eq "foo"
      t.get("profile_user_age").should eq 20
      t.get("profile").as_h["user"].as_h["name"].should eq "foo"
      t.get("profile").as_h["user"].as_h["age"].should eq 20
    end

    it "should getts from json raw" do
      t = Totem::Config.parse %Q{{"profile_user_name":"foo", "profile_user_age": 20}}, "json", "_"

      t.get("profile_user_name").should eq "foo"
      t.get("profile_user_age").should eq 20
      t.get("profile").as_h["user"].as_h["name"].should eq "foo"
      t.get("profile").as_h["user"].as_h["age"].should eq 20
    end

    it "should getts from yaml raw" do
      t = Totem::Config.parse %Q{---\nprofile_user_name: "foo"\nprofile_user_age: 20}, "yaml", "_"

      t.get("profile_user_name").should eq "foo"
      t.get("profile_user_age").should eq 20
      t.get("profile").as_h["user"].as_h["name"].should eq "foo"
      t.get("profile").as_h["user"].as_h["age"].should eq 20
    end

    it "should getts from dotenv raw" do
      t = Totem::Config.parse %Q{PROFILE_USER_NAME=foo\nPROFILE_USER_AGE=20}, "env", "_"

      t.get("profile_user_name").should eq "foo"
      t.get("profile_user_age").should eq "20"
      t.get("profile").as_h["user"].as_h["name"].should eq "foo"
      t.get("profile").as_h["user"].as_h["age"].should eq "20"
    end
  end

  describe "remote providers" do
    describe "with reds" do
      it "should gets use key" do
        with_redis do |endpoint|
          t = Totem::Config.new
          t.add_remote provider: "redis", endpoint: endpoint
          t.get("name").should eq "foo"
          t.get("config_development.json").should eq json_raw
          t.get("config_development").should eq json_raw
        end
      end

      it "should gets use path with extname" do
        with_redis do |endpoint|
          t = Totem::Config.new
          t.add_remote endpoint: endpoint, path: "config_development.json"
          json_spec_group t
        end
      end

      it "should gets use path without extname" do
        with_redis do |endpoint|
          t = Totem::Config.new
          t.config_type = "json"
          t.add_remote endpoint: endpoint, path: "config_development"
          json_spec_group t
        end
      end

      it "throws an exception use path without extname and config_type" do
        with_redis do |endpoint|
          t = Totem::Config.new
          expect_raises Totem::RemoteProviderError do
            t.add_remote provider: "redis", endpoint: endpoint, path: "config_development"
          end
        end
      end
    end

    describe "with etcd" do
      it "should gets use key" do
        with_etcd do |endpoint|
          t = Totem::Config.new
          t.add_remote provider: "etcd", endpoint: endpoint
          t.get("/name").should eq "foo"
          t.get("name").should eq "foo"
          t.get("config/development.json").should eq json_raw
          t.get("config/development").should eq json_raw
        end
      end

      it "should gets use path with extname" do
        with_etcd do |endpoint|
          t = Totem::Config.new
          t.add_remote provider: "etcd", endpoint: endpoint, path: "/config/development.json"
          json_spec_group t
        end
      end

      it "should gets use path without extname" do
        with_etcd do |endpoint|
          t = Totem::Config.new
          t.config_type = "json"
          t.add_remote provider: "etcd", endpoint: endpoint, path: "/config/development"
          json_spec_group t
        end
      end

      it "throws an exception use path without extname and config_type" do
        with_etcd do |endpoint|
          t = Totem::Config.new
          expect_raises Totem::RemoteProviderError do
            t.add_remote provider: "etcd", endpoint: endpoint, path: "/config/development"
          end
        end
      end
    end

    it "throws an exception when unmatched provider name" do
      t = Totem::Config.new
      expect_raises Totem::UnsupportedRemoteProviderError do
        t.add_remote endpoint: "asdfasdf"
      end
    end

    it "throws an exception when missing endpoint" do
      t = Totem::Config.new
      expect_raises Totem::RemoteProviderError do
        t.add_remote
      end

      expect_raises Totem::RemoteProviderError do
        t.add_remote
      end
    end
  end
end
