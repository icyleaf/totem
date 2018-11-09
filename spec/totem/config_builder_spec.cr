require "../spec_helper"

module ConfigBuilderSpec
  struct Config
    include Totem::ConfigBuilder

    build do
      config_type "yaml"
      config_paths ["/etc/totem", "~/.totem", "spec/fixtures"]
    end
  end

  struct Clothes
    include JSON::Serializable

    property jacket : String
  end

  struct Profile
    include Totem::ConfigBuilder

    property name : String
    property hobbies : Array(String)
    property clothing : Clothes

    build do
      config_type "yaml"
      config_paths ["/etc/totem", "~/.totem", "spec/fixtures"]
    end
  end

  struct Database
    include Totem::ConfigBuilder

    property host : String
    property port : Int32
    property database : String
    property username : String
    property password : String

    build do
      config_type "yaml"
      config_paths ["spec/fixtures/envs"]
      config_envs ["development", "production"]
    end
  end
end

describe Totem::ConfigBuilder do
  describe ".configure" do
    describe "loads" do
      it "should works" do
        config = ConfigBuilderSpec::Config.configure

        config["name"].should eq "steve"
        config["hobbies"].size.should eq 3
        config["hobbies"].as_a.last.should eq "go"
        config["clothing"].as_h["jacket"].should eq "leather"
      end

      it "should works with given file" do
        config = ConfigBuilderSpec::Config.configure("spec/fixtures/config.json", 0)

        config["name"].should eq "Cake"
        config["batters"].size.should eq 1
        config["batters"].as_h["batter"].as_a.first.as_h["type"].should eq "Regular"
      end

      it "should works with block" do
        config = ConfigBuilderSpec::Config.configure do |c|
          c.set("name", "tavares")
        end

        config["name"].should eq "tavares"
        config["hobbies"].size.should eq 3
        config["hobbies"].as_a.last.should eq "go"
        config["clothing"].as_h["jacket"].should eq "leather"
      end

      it "should works with given file and block" do
        config = ConfigBuilderSpec::Config.configure("spec/fixtures/config.json") do |c|
          c.set("name", "tavares")
        end

        config["name"].should eq "tavares"
        config["batters"].size.should eq 1
        config["batters"].as_h["batter"].as_a.first.as_h["type"].should eq "Regular"
      end

      it "should works with env" do
        config = ConfigBuilderSpec::Database.configure(environment: "production")
        config.host.should eq "db.example.com"
      end

      it "should works with given file and env" do
        config = ConfigBuilderSpec::Database.configure(
          file: File.join(fixture_path, "env", "config.yaml"),
          environment: "development"
        )

        config.host.should eq "localhost"
      end

      it "should works with env and block" do
        config = ConfigBuilderSpec::Database.configure(environment: "production") do |c|
          c.set("env", "production")
        end

        config.host.should eq "db.example.com"
        config.get("env").should eq "production"
      end

      it "throws an exception with unkown file" do
        expect_raises Totem::NotFoundConfigFileError do
          ConfigBuilderSpec::Database.configure(file: "unkown-file")
        end
      end

      it "throws an exception with unkown env" do
        expect_raises Totem::NotFoundConfigFileError do
          ConfigBuilderSpec::Database.configure(environment: "test")
        end
      end
    end

    describe "mapping" do
      it "should works" do
        profile = ConfigBuilderSpec::Profile.configure

        profile.name.should eq "steve"
        profile.hobbies.size.should eq 3
        profile.hobbies.last.should eq "go"
        profile.clothing.jacket.should eq "leather"
      end

      it "should works with block" do
        profile = ConfigBuilderSpec::Profile.configure do |config|
          config.set("name", "tavares")
        end

        profile.name.should eq "tavares"
        profile.hobbies.size.should eq 3
        profile.hobbies.last.should eq "go"
        profile.clothing.jacket.should eq "leather"
      end
    end
  end
end
