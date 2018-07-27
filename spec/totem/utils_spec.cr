require "../spec_helper"

private def it_detect_config_type(string, expected, file = __FILE__, line = __LINE__)
  it "should detect #{string}", file, line do
    Totem::Utils.config_type(string).should eq expected
  end
end

private def it_detect_env_key(string, expected, env_prefix : String? = nil, file = __FILE__, line = __LINE__)
  it "should detect #{string}", file, line do
    Totem::Utils.env_key(string, env_prefix).should eq expected
  end
end

describe Totem::Utils do
  describe Totem::Utils::FileHelper do
    describe ".config_type" do
      it_detect_config_type "config.json", "json"
      it_detect_config_type "./config.yml", "yml"
      it_detect_config_type "/path/to/your/path/.env", "env"
      it_detect_config_type ".sample.zshrc", "zshrc"
      it_detect_config_type "~/.rvm/db/user", nil
    end
  end

  describe Totem::Utils::EnvHelper do
    describe ".env_key" do
      it_detect_env_key "name", "NAME"
      it_detect_env_key "TOTEM_NAME", "TOTEM_NAME"
      it_detect_env_key "user_name", "TOTEM_USER_NAME", env_prefix: "totem"
      it_detect_env_key "name", "TOTEM_NAME", env_prefix: "totem_"
    end
  end
end
