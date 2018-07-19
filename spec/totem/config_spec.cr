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
