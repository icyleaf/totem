require "../../spec_helper"

describe Totem::ConfigTypes::JSON do
  it "should reads" do
    adapter = Totem::ConfigTypes::JSON.new
    data = adapter.read <<-EOF
{
  "id": 123,
  "user": {
    "name": "foo",
    "age": 20
  },
  "tags": [
    "profile",
    "user"
  ]
}
EOF

    data["id"].should eq 123
    data["user"].should be_a Totem::Any
    data["user"].as_h.should be_a Hash(String, Totem::Any)
    data["user"].as_h["name"].should eq "foo"
    data["tags"].should be_a Totem::Any
    data["tags"].as_a.should be_a Array(Totem::Any)
    data["tags"].as_a.first.should eq "profile"
  end

  # FIXME: depend on config parse
  # it "should writes" do
  #   totem = Totem.from_json json_raw
  #   adapter = Totem::ConfigTypes::JSON.new

  #   with_tempfile("config.json") do |path|
  #     File.open(path, "w") do |file|
  #       adapter.write(file, totem)
  #     end

  #     data = ::JSON.parse(File.read(path)).as_h
  #     data.each do |key, value|
  #       totem[key].should eq value.raw
  #     end
  #   end
  # end
end
