require "../../spec_helper"

private def it_parse(string, expected, file = __FILE__, line = __LINE__)
  it "should parse #{string}", file, line do
    string.snakecase.should eq expected
  end
end

describe String do
  describe ".snakecase" do
    it_parse "helloworld", "helloworld"
    it_parse "helloWorld", "hello_world"
    it_parse "HelloWorld", "hello_world"
    it_parse "AAbb", "a_abb"
    it_parse "aBaB", "a_ba_b"
    it_parse "ABCD", "a_b_c_d"
  end
end
