require "../spec_helper"

describe Totem::Any do
  describe "casts" do
    it "gets nil" do
      Totem::Any.new(nil).as_nil.should be_nil

      json = JSON.parse(%Q{[null]})
      Totem::Any.new(json).as_a.first.as_nil.should be_nil

      yaml = YAML.parse(%Q{- null})
      Totem::Any.new(yaml).as_a.first.as_nil.should be_nil
    end

    it "gets bool" do
      Totem::Any.new(true).as_bool.should be_true
      Totem::Any.new(true).as_bool?.should be_true
      Totem::Any.new(false).as_bool.should be_false
      Totem::Any.new(false).as_bool?.should be_false
      Totem::Any.new(1).as_bool.should be_true
      Totem::Any.new(0).as_bool.should be_false
      Totem::Any.new("TRUE").as_bool.should be_true
      Totem::Any.new("t").as_bool.should be_true
      Totem::Any.new("yes").as_bool.should be_true
      Totem::Any.new("Y").as_bool.should be_true
      Totem::Any.new("on").as_bool.should be_true
      Totem::Any.new("1").as_bool.should be_true
      Totem::Any.new("FALSE").as_bool.should be_false
      Totem::Any.new("f").as_bool.should be_false
      Totem::Any.new("no").as_bool.should be_false
      Totem::Any.new("N").as_bool.should be_false
      Totem::Any.new("off").as_bool.should be_false
      Totem::Any.new("0").as_bool.should be_false

      json = JSON.parse(%Q{[true, false]})
      Totem::Any.new(json).as_a.first.as_bool.should eq true
      Totem::Any.new(json).as_a.first.as_bool?.should eq true
      Totem::Any.new(json).as_a.last.as_bool.should eq false
      Totem::Any.new(json).as_a.last.as_bool?.should eq false

      yaml = YAML.parse(%Q{- true\n- t\n- false})
      Totem::Any.new(yaml).as_a.first.as_bool.should eq true
      Totem::Any.new(yaml).as_a.first.as_bool?.should eq true
      Totem::Any.new(yaml).as_a.last.as_bool.should eq false
      Totem::Any.new(yaml).as_a.last.as_bool?.should eq false
      Totem::Any.new(yaml).as_a[1].as_bool.should be_true

      expect_raises TypeCastError do
        Totem::Any.new(json).as_bool
      end

      expect_raises TypeCastError do
        Totem::Any.new(yaml).as_bool
      end
    end

    it "gets int" do
      Totem::Any.new(123).as_i.should eq 123
      Totem::Any.new(123).as_i?.should eq 123
      Totem::Any.new(123456789123456).as_i64.should eq 123456789123456
      Totem::Any.new(123456789123456).as_i64?.should eq 123456789123456
      Totem::Any.new(true).as_i?.should eq 1

      json = JSON.parse(%Q{[123, 123456789123456]})
      Totem::Any.new(json).as_a.first.as_i.should eq 123
      Totem::Any.new(json).as_a.first.as_i?.should eq 123
      Totem::Any.new(json).as_a.last.as_i64.should eq 123456789123456
      Totem::Any.new(json).as_a.last.as_i64?.should eq 123456789123456

      yaml = YAML.parse(%Q{- 123\n- 123456789123456})
      Totem::Any.new(yaml).as_a.first.as_i.should eq 123
      Totem::Any.new(yaml).as_a.first.as_i?.should eq 123
      Totem::Any.new(yaml).as_a.last.as_i64.should eq 123456789123456
      Totem::Any.new(yaml).as_a.last.as_i64?.should eq 123456789123456
    end

    it "gets float" do
      Totem::Any.new(123.45).as_f.should eq 123.45
      Totem::Any.new(123.45).as_f?.should eq 123.45
      Totem::Any.new(123.45).as_f32.should eq 123.45_f32
      Totem::Any.new(123.45).as_f32?.should eq 123.45_f32
      Totem::Any.new(true).as_f?.should be_nil

      json = JSON.parse(%Q{[123.45]})
      Totem::Any.new(json).as_a.first.as_f.should eq 123.45
      Totem::Any.new(json).as_a.first.as_f?.should eq 123.45
      Totem::Any.new(json).as_a.first.as_f32.should eq 123.45_f32
      Totem::Any.new(json).as_a.first.as_f32?.should eq 123.45_f32

      yaml = YAML.parse(%Q{- 123.45})
      Totem::Any.new(yaml).as_a.first.as_f.should eq 123.45
      Totem::Any.new(yaml).as_a.first.as_f?.should eq 123.45
      Totem::Any.new(yaml).as_a.first.as_f32.should eq 123.45_f32
      Totem::Any.new(yaml).as_a.first.as_f32?.should eq 123.45_f32
    end

    it "gets string" do
      Totem::Any.new("hello").as_s.should eq "hello"
      Totem::Any.new("hello").as_s?.should eq "hello"
      Totem::Any.new(true).as_s?.should be_nil

      json = JSON.parse(%Q{["hello"]})
      Totem::Any.new(json).as_a.first.as_s.should eq "hello"
      Totem::Any.new(json).as_a.first.as_s?.should eq "hello"

      yaml = YAML.parse(%Q{- hello})
      Totem::Any.new(yaml).as_a.first.as_s.should eq "hello"
      Totem::Any.new(yaml).as_a.first.as_s?.should eq "hello"
    end

    it "gets time" do
      current = Time.local
      Totem::Any.new(current).as_time.should eq current
      Totem::Any.new(current).as_time?.should eq current
      Totem::Any.new(true).as_time?.should be_nil

      Totem::Any.new("2018-09-20 16:54:41+08:00").as_time.should eq Time.local(2018, 9, 20, 16, 54, 41, location: Time::Location::UTC)
      Totem::Any.new("2018-09-20 16:54:41+08:00").as_time?(Time::Location.load("Asia/Shanghai")).should eq Time.local(2018, 9, 20, 16, 54, 41, location: Time::Location.load("Asia/Shanghai"))

      json = JSON.parse(%Q{["2018-09-20 16:54:41+08:00"]})
      Totem::Any.new(json).as_a.first.as_time.should eq Time.local(2018, 9, 20, 16, 54, 41, location: Time::Location::UTC)
      Totem::Any.new(json).as_a.first.as_time?(Time::Location.load("Asia/Shanghai")).should eq Time.local(2018, 9, 20, 16, 54, 41, location: Time::Location.load("Asia/Shanghai"))

      yaml = YAML.parse(%Q{- 2018-09-20 16:54:41+08:00})
      Totem::Any.new(yaml).as_a.first.as_time.should eq Time.local(2018, 9, 20, 16, 54, 41, location: Time::Location.load("Asia/Shanghai"))
      Totem::Any.new(yaml).as_a.first.as_time?(Time::Location.load("Asia/Shanghai")).should eq Time.local(2018, 9, 20, 16, 54, 41, location: Time::Location.load("Asia/Shanghai"))
    end

    it "gets array" do
      given_value = [Totem::Any.new(1), Totem::Any.new(2), Totem::Any.new(3)]
      Totem::Any.new([1, 2, 3]).as_a.should eq given_value
      Totem::Any.new([1, 2, 3]).as_a?.should eq given_value
      Totem::Any.new("true").as_a?.should be_nil

      json = JSON.parse(%Q{[1, 2, 3]})
      Totem::Any.new(json).as_a.should eq given_value
      Totem::Any.new(json).as_a?.should eq given_value

      yaml = YAML.parse(%Q{- 1\n- 2\n- 3})
      Totem::Any.new(yaml).as_a.should eq given_value
      Totem::Any.new(yaml).as_a?.should eq given_value
    end

    it "gets hash" do
      given_value = {"foo" => Totem::Any.new("bar")}
      Totem::Any.new({"foo" => "bar"}).as_h.should eq given_value
      Totem::Any.new({"foo" => "bar"}).as_h?.should eq given_value
      Totem::Any.new("true").as_h?.should be_nil

      json = JSON.parse(%Q{{"foo":"bar"}})
      Totem::Any.new(json).as_h.should eq given_value
      Totem::Any.new(json).as_h?.should eq given_value

      yaml = YAML.parse(%Q{{foo: bar}})
      Totem::Any.new(yaml).as_h.should eq given_value
      Totem::Any.new(yaml).as_h?.should eq given_value
    end
  end

  describe "#size" do
    it "of array" do
      Totem::Any.new([1, 2, 3]).size.should eq 3
      Totem::Any.new(JSON.parse(%Q{[1, 2, 3]})).size.should eq 3
      Totem::Any.new(YAML.parse(%Q{- 1\n- 2\n- 3})).size.should eq 3
    end

    it "of hash" do
      Totem::Any.new({"foo" => "bar"}).size.should eq 1
      Totem::Any.new(JSON.parse(%Q{{"foo":"bar"}})).size.should eq 1
      Totem::Any.new(YAML.parse(%Q{{foo: bar}})).size.should eq 1
    end
  end

  describe "#[]" do
    it "of array" do
      Totem::Any.new([1, 2, 3])[1].raw.should eq 2
      Totem::Any.new(JSON.parse(%Q{[1, 2, 3]}))[1].raw.should eq 2
      Totem::Any.new(YAML.parse(%Q{- 1\n- 2\n- 3}))[1].raw.should eq 2
    end

    it "of hash" do
      Totem::Any.new({"foo" => "bar"})["foo"].raw.should eq "bar"
      Totem::Any.new(JSON.parse(%Q{{"foo":"bar"}}))["foo"].raw.should eq "bar"
      Totem::Any.new(YAML.parse(%Q{{foo: bar}}))["foo"].raw.should eq "bar"
    end
  end

  describe "#[]?" do
    it "of array" do
      Totem::Any.new([1, 2, 3])[1]?.not_nil!.raw.should eq 2
      Totem::Any.new([1, 2, 3])[3]?.should be_nil
      Totem::Any.new([true, false])[1]?.not_nil!.raw.should eq false
      Totem::Any.new(JSON.parse(%Q{[1, 2, 3]}))[1]?.not_nil!.raw.should eq 2
      Totem::Any.new(JSON.parse(%Q{[1, 2, 3]}))[3]?.should be_nil
      Totem::Any.new(YAML.parse(%Q{- 1\n- 2\n- 3}))[1]?.not_nil!.raw.should eq 2
      Totem::Any.new(YAML.parse(%Q{- 1\n- 2\n- 3}))[3]?.should be_nil
    end

    it "of hash" do
      Totem::Any.new({"foo" => "bar"})["foo"]?.not_nil!.raw.should eq "bar"
      Totem::Any.new({"foo" => "bar"})["fox"]?.should be_nil
      Totem::Any.new({"foo" => false})["foo"]?.not_nil!.raw.should eq false
      Totem::Any.new(JSON.parse(%Q{{"foo":"bar"}}))["foo"]?.not_nil!.raw.should eq "bar"
      Totem::Any.new(JSON.parse(%Q{{"foo":"bar"}}))["fox"]?.should be_nil
      Totem::Any.new(YAML.parse(%Q{{foo: bar}}))["foo"]?.not_nil!.raw.should eq "bar"
      Totem::Any.new(YAML.parse(%Q{{foo: bar}}))["fox"]?.should be_nil
    end
  end

  it "should equals" do
    Totem::Any.new(nil).should eq nil
    Totem::Any.new(true).should eq true
    Totem::Any.new("foo").should eq "foo"
    Totem::Any.new(123).should eq 123
    Totem::Any.new(123_i64).should eq 123_i64
    Totem::Any.new(123.45).should eq 123.45
    Totem::Any.new([1, 2, 3]).should eq([1, 2, 3])
    Totem::Any.new({"foo" => "bar"}).should eq({"foo" => "bar"})
    Totem::Any.new(JSON::Any.new(raw: "foo")).should eq JSON::Any.new(raw: "foo")
    Totem::Any.new(YAML::Any.new(raw: "foo")).should eq YAML::Any.new(raw: "foo")
  end

  it "dups" do
    any = Totem::Any.new([1, 2, 3])
    any2 = any.dup
    any2.as_a.should_not be any.as_a
  end

  it "clones" do
    any = Totem::Any.new([[1], 2, 3])
    any2 = any.clone
    any2.as_a[0].as_a.should_not be any.as_a[0].as_a
  end
end

describe JSON::Any do
  describe "#to_json" do
    json = JSON.parse load_fixture("config.json")
    json.to_yaml.should eq %Q{---\nid: "0001"\ntype: donut\nname: Cake\ngluten_free: false\nppu: 0.55\nduty_free: "no"\nbatters:\n  batter:\n  - type: Regular\n  - type: Chocolate\n  - type: Blueberry\n  - type: Devil's Food\n}
  end
end

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
