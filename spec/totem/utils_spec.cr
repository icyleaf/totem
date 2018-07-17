require "../spec_helper"

private def it_detect(string, expected, file = __FILE__, line = __LINE__)
  it "should detect #{string}", file, line do
    Totem::Utils.config_type(string).should eq expected
  end
end

describe Totem::Utils do
  describe Totem::Utils::FileHelper do
    describe ".config_type" do
      it_detect "config.json", "json"
      it_detect "./config.yml", "yml"
      it_detect "/path/to/your/path/.env", "env"
      it_detect ".sample.zshrc", "zshrc"
      it_detect "~/.rvm/db/user", nil
    end
  end
end
