require "../../spec_helper"

describe JSON::Any do
  describe "#to_json" do
    json = JSON.parse load_fixture("config.json")
    json.to_yaml.should eq %Q{---\nid: "0001"\ntype: donut\nname: Cake\ngluten_free: false\nppu: 0.55\nduty_free: "no"\nbatters:\n  batter:\n  - type: Regular\n  - type: Chocolate\n  - type: Blueberry\n  - type: Devil's Food\n}
  end
end
