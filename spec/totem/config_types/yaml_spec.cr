require "../../spec_helper"

describe Totem::ConfigTypes::YAML do
  it "should reads" do
    adapter = Totem::ConfigTypes::YAML.new
    data = adapter.read <<-EOF
---
id: 123
user:
  name: foo
  age: 20
tags:
  - profile
  - user
EOF

    data["id"].should eq 123
    data["user"].should be_a ::YAML::Any
    data["user"].as_h.should be_a Hash(::YAML::Any, ::YAML::Any)
    data["user"].as_h["name"].should eq "foo"
    data["tags"].should be_a ::YAML::Any
    data["tags"].as_a.should be_a Array(::YAML::Any)
    data["tags"].as_a.first.should eq "profile"
  end

  it "should writes" do
    totem = Totem.from_yaml yaml_raw
    adapter = Totem::ConfigTypes::YAML.new

    with_tempfile("config.yaml") do |path|
      File.open(path, "w") do |file|
        adapter.write(file, totem)
      end

      data = ::YAML.parse(File.read(path)).as_h
      data.each do |key, value|
        totem[key.to_s].should eq value.raw
      end
    end
  end
end
