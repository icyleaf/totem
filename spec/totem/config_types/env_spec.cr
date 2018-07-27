require "../../spec_helper"

describe Totem::ConfigTypes::Env do
  it "should reads" do
    adapter = Totem::ConfigTypes::Env.new
    data = adapter.read <<-EOF
ID=123
USER_NAME=foo
USER_AGE=20
TAGS=profile
EOF

    data["id"].should eq "123"
    data["user_name"].should eq "foo"
    data["user_age"].should eq "20"
    data["tags"].should eq "profile"
  end

  it "should writes" do
    totem = Totem.from_json json_raw
    adapter = Totem::ConfigTypes::JSON.new

    with_tempfile("config.env") do |path|
      File.open(path, "w") do |file|
        adapter.write(file, totem)
      end

      Poncho.parse(path).each do |key, value|
        totem[key].should eq value
      end
    end
  end
end
