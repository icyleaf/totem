require "popcorn"

module Totem
  # `Totem::Any` is a convenient wrapper around all possible types(`Totem::Any::Type`) and
  # can be used for traversing dynamic or unkown types.
  struct Any
    alias Type = String | Int32 | Int64 | Float64 | Bool | Nil | Array(Any) | Hash(String, Any) | YAML::Any | JSON::Any

    getter raw : Type

    def initialize(@raw : Type)
    end

    def initialize(raw : Array(_))
      @raw = raw.map { |v| Any.new(v) }
    end

    def initialize(raw : Hash(String, _))
      @raw = Hash(String, Any).new.tap do |obj|
        raw.each do |key, value|
          obj[key] = Any.new(value)
        end
      end
    end

    def as_i?
      Popcorn.to_int?(@raw)
    end

    def as_i
      Popcorn.to_int(@raw)
    end

    def as_i64?
      Popcorn.to_int64?(@raw)
    end

    def as_i64
      Popcorn.to_int64(@raw)
    end

    def as_f?
      Popcorn.to_float?(@raw)
    end

    def as_f
      Popcorn.to_float(@raw)
    end

    def as_bool?
      Popcorn.to_bool?(@raw)
    end

    def as_bool
      Popcorn.to_bool(@raw)
    end

    def as_nil : Nil
      case object = @raw
      when JSON::Any, YAML::Any
        object.as_nil
      else
        object.as(Nil)
      end
    end

    def as_h? : Hash(String, Any)?
      as_h if @raw.is_a?(Hash) ||
              (@raw.is_a?(JSON::Any) && @raw.as(JSON::Any).as_h?) ||
              (@raw.is_a?(YAML::Any) && @raw.as(YAML::Any).as_h?)
    end

    def as_h : Hash(String, Any)
      case object = @raw
      when Hash
        object.as(Hash(String, Any))
      when YAML::Any, JSON::Any
        Hash(String, Any).new.tap do |obj|
          object.as_h.each do |key, value|
            obj[key.to_s] = Any.new(value)
          end
        end
      else
        Popcorn.raise_error!(object.class.to_s, "Hash")
      end
    end

    def as_a? : Array(Any)?
      as_a if @raw.is_a?(Array) ||
              (@raw.is_a?(JSON::Any) && @raw.as(JSON::Any).as_a?) ||
              (@raw.is_a?(YAML::Any) && @raw.as(YAML::Any).as_a?)
    end

    def as_a : Array(Any)
      case object = @raw
      when Array
        object.as(Array)
      when YAML::Any, JSON::Any
        object.as_a.map { |value| Any.new(value) }
      else
        Popcorn.raise_error!(object.class.to_s, "Array")
      end
    end

    def [](key : Int) : Any
      object = @raw
      if object.is_a?(Array)
        object[key]
      elsif object.is_a?(JSON::Any) && (json = object.as(JSON::Any)) && json.as_a?
        as_a[key]
      elsif object.is_a?(YAML::Any) && (yaml = object.as(YAML::Any)) && yaml.as_a?
        as_a[key]
      else
        raise Error.new("Expected Array for #[](index : Int), not #{object.class}")
      end
    end

    def [](key : String) : Any
      object = @raw
      if object.is_a?(Hash)
        object[key]
      elsif object.is_a?(JSON::Any) && (json = object.as(JSON::Any)) && json.as_h?
        as_h[key]
      elsif object.is_a?(YAML::Any) && (yaml = object.as(YAML::Any)) && yaml.as_h?
        as_h[key]
      else
        raise Error.new("Expected Hash for #[](index : String), not #{object.class}")
      end
    end

    def []?(key : Int) : Any?
      object = @raw
      if object.is_a?(Array)
        object[key]?
      elsif object.is_a?(JSON::Any) && (json = object.as(JSON::Any)) && json.as_a?
        as_a[key]?
      elsif object.is_a?(YAML::Any) && (yaml = object.as(YAML::Any)) && yaml.as_a?
        as_a[key]?
      else
        raise Error.new("Expected Array for #[](index : Int), not #{object.class}")
      end
    end

    def []?(key : String) : Any?
      object = @raw
      if object.is_a?(Hash)
        object[key]?
      elsif object.is_a?(JSON::Any) && (json = object.as(JSON::Any)) && json.as_h?
        as_h[key]?
      elsif object.is_a?(YAML::Any) && (yaml = object.as(YAML::Any)) && yaml.as_h?
        as_h[key]?
      else
        raise Error.new("Expected Hash for #[](index : String), not #{object.class}")
      end
    end

    def size : Int
      object = @raw
      if object.is_a?(Array) || object.is_a?(Hash)
        object.size
      elsif object.is_a?(JSON::Any) && (json = object.as(JSON::Any)) && json.as_h?
        json.as_h.size
      elsif object.is_a?(JSON::Any) && (json = object.as(JSON::Any)) && json.as_a?
        json.as_a.size
      elsif object.is_a?(YAML::Any) && (yaml = object.as(YAML::Any)) && yaml.as_h?
        yaml.as_h.size
      elsif object.is_a?(YAML::Any) && (yaml = object.as(YAML::Any)) && yaml.as_a?
        yaml.as_a.size
      else
        raise Error.new("Expected Arra, Hash for #size, not #{object.class}")
      end
    end

    def as_s
      case object = @raw
      when YAML::Any, JSON::Any
        object.as_s
      else
        object.as(String)
      end
    end

    def as_s?
      case object = @raw
      when YAML::Any, JSON::Any
        object.as_s?
      when String
        object.as(String)
      end
    end

    def dup
      Any.new(@raw.dup)
    end

    def clone
      Any.new(@raw.clone)
    end

    # See `Object#hash(hasher)`
    def_hash raw

    # :nodoc:
    def to_yaml(yaml : YAML::Nodes::Builder)
      @raw.to_yaml(yaml)
    end

    # :nodoc:
    def to_json(json : JSON::Builder)
      @raw.to_json(json)
    end

    # :nodoc:
    def inspect(io)
      @raw.inspect(io)
    end

    # :nodoc:
    def to_s(io)
      @raw.to_s(io)
    end

    # :nodoc:
    def pretty_print(pp)
      @raw.pretty_print(pp)
    end
  end
end
