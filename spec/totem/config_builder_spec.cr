require "../spec_helper"

module ConfigBuilderSpec
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
      # debugging true
      config_type "yaml"
      config_paths ["/etc/totem", "~/.totem", "spec/fixtures"]
    end
  end
end

describe Totem::ConfigBuilder do
  describe "configure" do
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
