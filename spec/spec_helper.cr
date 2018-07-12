require "spec"
require "../src/totem"

def fixture_path
  path = File.expand_path("../fixtures/", __FILE__)
end

def load_fixture(filename : String)
  File.read_lines(File.join(fixture_path, filename)).join("\n")
end
