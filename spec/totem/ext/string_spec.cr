require "../../spec_helper"

private def it_parse(string, expected, file = __FILE__, line = __LINE__)
  it "should parse #{string}", file, line do
    string.snakecase.should eq expected
  end
end

private def it_cast(string, expected, strict = true, file = __FILE__, line = __LINE__)
  it "should cast #{string}", file, line do
    string.to_bool(strict).should expected
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

  describe ".to_bool" do
    describe "with strict mode" do
      it_cast "true", be_true, true
      it_cast "True", be_true, true
      it_cast "FALSE", be_false, true
      it_cast "falSE", be_false, true
      it_cast "nil", be_nil, true
      it_cast "0", be_nil, true
      it_cast "1", be_nil, true
      it_cast "YES", be_nil, true
    end

    describe "without strict mode" do
      it_cast "tRue", be_true, false
      it_cast "T", be_true, false
      it_cast "Yes", be_true, false
      it_cast "Y", be_true, false
      it_cast "1", be_true, false
      it_cast "falSE", be_false, false
      it_cast "F", be_false, false
      it_cast "No", be_false, false
      it_cast "n", be_false, false
      it_cast "0", be_false, false
      it_cast "nil", be_nil, false
    end
  end
end
