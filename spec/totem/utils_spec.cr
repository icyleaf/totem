require "../spec_helper"

private def it_detect(string, expected, file = __FILE__, line = __LINE__)
  it "should detect {string}", file, line do
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

  describe Totem::Utils::BoolHelper do
    describe ".as_bool?" do
      it "should return true/false with matched string" do
        Totem::Utils.as_bool?("true").should be_true
        Totem::Utils.as_bool?("True").should be_true
        Totem::Utils.as_bool?("FALSE").should be_false
        Totem::Utils.as_bool?("falSE").should be_false
      end

      it "return nil with other string" do
        Totem::Utils.as_bool?("nil").should be_nil
        Totem::Utils.as_bool?("0").should be_nil
        Totem::Utils.as_bool?("1").should be_nil
        Totem::Utils.as_bool?("YES").should be_nil
      end
    end
  end
end
