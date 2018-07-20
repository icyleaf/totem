require "../../spec_helper"

describe YAML::Any do
  describe "#to_json" do
    yaml = YAML.parse load_fixture("config.yaml")
    yaml.to_json.should eq %Q{{"Hacker":true,"name":"steve","hobbies":["skateboarding","snowboarding","go"],"clothing":{"jacket":"leather","trousers":"denim","pants":{"size":"large"}},"gender":true,"age":35,"eyes":"brown"}}
  end
end

describe Slice do
  describe "#to_json" do
    Slice(UInt8).empty.to_json.should eq "[]"
    Slice.new(3) { |i| i + 10 }.to_json.should eq "[10,11,12]"
  end
end

describe Char do
  describe "#to_json" do
    '1'.to_json.should eq %Q{"1"}
    't'.to_json.should eq %Q{"t"}
  end
end
