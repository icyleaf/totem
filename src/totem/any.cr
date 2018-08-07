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
        Popcorn.cast_error!(object.class.to_s, "Hash")
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
        Popcorn.cast_error!(object.class.to_s, "Array")
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
        raise Error.new("Expected Array for #[](index : Totem::Any), not #{object.class}")
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
        raise Error.new("Expected Array for #[](index : Totem::Any), not #{object.class}")
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
    def pretty_print(pp)
      @raw.pretty_print(pp)
    end

    # Returns `true` if both `self` and *other*'s raw object are equal.
    def ==(other : Totem::Any)
      raw == other.raw
    end

    # Returns `true` if the raw object is equal to *other*.
    def ==(other)
      raw == other
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

# :nodoc:
module Popcorn::Cast
  # Alias to `to_int32?`
  def to_int?(raw : Totem::Any)
    to_int32?(raw)
  end

  # Returns the `Int32` or `Nil` value represented by given data type.
  def to_int32?(raw : Totem::Any)
    value = find(raw)
    to_int32?(value) unless value.nil?
  end

  # Returns the `Int8` or `Nil` value represented by given data type.
  def to_int8?(raw : Totem::Any)
    value = find(raw)
    to_int8?(value) unless value.nil?
  end

  # Returns the `Int16` or `Nil` value represented by given data type.
  def to_int16?(raw : Totem::Any)
    value = find(raw)
    to_int16?(value) unless value.nil?
  end

  # Returns the `Int64` or `Nil` value represented by given data type.
  def to_int64?(raw : Totem::Any)
    value = find(raw)
    to_int64?(value) unless value.nil?
  end

  # Returns the `UInt32` or `Nil` value represented by given data type.
  def to_uint?(raw : Totem::Any)
    to_uint32?(raw)
  end

  # Alias to `to_uint?`
  def to_uint32?(raw : Totem::Any)
    value = find(raw)
    to_uint32?(value) unless value.nil?
  end

  # Returns the `Int8` or `Nil` value represented by given data type.
  def to_uint8?(raw : Totem::Any)
    value = find(raw)
    to_uint8?(value) unless value.nil?
  end

  # Returns the `UInt16` or `Nil` value represented by given data type.
  def to_uint16?(raw : Totem::Any)
    value = find(raw)
    to_uint16?(value) unless value.nil?
  end

  # Returns the `UInt64` or `Nil` value represented by given data type.
  def to_uint64?(raw : Totem::Any)
    value = find(raw)
    to_uint64?(value) unless value.nil?
  end

  # Returns the `Float64` or `Nil` value represented by given data type.
  def to_float?(raw : Totem::Any)
    to_float64?(raw)
  end

  # Alias to `to_float64?`
  def to_float64?(raw : Totem::Any)
    value = find(raw)
    to_float64?(value) unless value.nil?
  end

  # Returns the `Float32` or `Nil` value represented by given data type.
  def to_float32?(raw : Totem::Any)
    value = find(raw)
    to_float32?(value) unless value.nil?
  end

  # Returns the `Time` or `Nil` value represented by given data type.
  #
  # - `location` argument applies for `Int`/`String` types
  # - `formatters` argument applies for `String` type.
  def to_time?(raw : Totem::Any, location : Time::Location? = nil, formatters : Array(String)? = nil)
    value = find(raw)
    to_time?(value, location, formatters) unless value.nil?
  end

  # Returns the `Bool` or `Nil` value represented by given data type.
  # It accepts true, t, yes, y, on, 1, false, f, no, n, off, 0. Any other value return Nil.gst
  def to_bool?(raw : Totem::Any)
    value = find(raw)
    to_bool?(value) unless value.nil?
  end

  # Returns the `Array` or `Nil` value represented by given Totem::Any type.
  def to_array?(raw : Totem::Any, target : T.class = String) forall T
    if data = raw.as_a?
      data.each_with_object(Array(T).new) do |v, obj|
        obj << cast(v.to_s, T).as(T)
      end
    elsif data = raw.as_h?
      data.each_with_object(Array(T).new) do |(k, v), obj|
        obj << cast(k.to_s, T).as(T) << cast(v.to_s, T).as(T)
      end
    else
      [cast(raw.to_s, T).as(T)]
    end
  end

  # Returns the `Hash` or `Nil` value represented by given Totem::Any type.
  def to_hash?(raw : Totem::Any, value : T.class = String) forall T
    return unless data = raw.as_h?
    data.each_with_object(Hash(String, T).new) do |(k, v), obj|
      obj[k.to_s] = cast(v, T).as(T)
    end
  end

  private def find(raw : Totem::Any)
    if value = raw.as_i64?
      return value
    end

    if value = raw.as_i?
      return value
    end

    if value = raw.as_f?
      return value
    end

    value = raw.as_bool?
    if !value.nil?
      return value
    end

    if value = raw.as_s?
      return value
    end
  end

  Popcorn::Cast.generate!
end

# :nodoc:
class Object
  def ===(other : Totem::Any)
    self === other.raw
  end
end

# :nodoc:
struct Value
  def ==(other : Totem::Any)
    self == other.raw
  end
end

# :nodoc:
class Reference
  def ==(other : Totem::Any)
    self == other.raw
  end
end

# :nodoc:
class Array
  def ==(other : Totem::Any)
    self == other.raw
  end
end

# :nodoc:
class Hash
  def ==(other : Totem::Any)
    self == other.raw
  end
end

# :nodoc:
struct YAML::Any
  def ==(other : Totem::Any)
    self == other.raw
  end

  def to_json(json : JSON::Builder)
    @raw.to_json(json)
  end
end

# :nodoc:
struct JSON::Any
  def ==(other : Totem::Any)
    self == other.raw
  end

  def to_yaml(yaml : YAML::Nodes::Builder)
    @raw.to_yaml(yaml)
  end
end

# :nodoc:
class Regex
  def ===(other : Totem::Any)
    value = self === other.raw
    $~ = $~
    value
  end
end

# :nodoc:
struct Slice
  # :nodoc:
  def to_json(json : JSON::Builder)
    json.array do
      to_a.each do |v|
        v.to_json(json)
      end
    end
  end
end

# :nodoc:
struct Char
  # :nodoc:
  def to_json(json : JSON::Builder)
    json.string(self)
  end
end
