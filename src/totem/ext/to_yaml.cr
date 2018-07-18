# :nodoc:
struct JSON::Any
  def to_yaml(yaml : YAML::Nodes::Builder)
    @raw.to_yaml(yaml)
  end
end
