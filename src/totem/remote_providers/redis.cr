require "redis"
require "json"

module Totem::RemoteProviders
  class Redis < Adapter
    def initialize(endpoint : String)
      @client = ::Redis.new(url: endpoint)
    end

    def get(key : String) : Any?
      if value = get_str(key)
        return Any.new(value)
      end

      if value = get_hash(key)
        return Any.new(value)
      end

      if value = get_set(key)
        return Any.new(value)
      end

      if value = get_zset(key)
        return Any.new(value)
      end
    end

    def get_str(key : String)
      @client.get(key)
    rescue ::Redis::Error
      nil
    end

    def get_hash(key : String)
      Hash(String, Any).new.tap do |obj|
        @client.hgetall(key).each_slice(2) do |key_value|
          key, value = key_value
          obj[key.to_s] = handle_value(value)
        end
      end
    rescue ::Redis::Error
      nil
    end

    def get_set(key : String)
      value = @client.smembers(key)
      value.each_with_object(Array(Any).new) do |value, obj|
        obj << handle_value(value)
      end
    rescue ::Redis::Error
      nil
    end

    def get_zset(key : String)
      Hash(String, Any).new.tap do |obj|
        @client.zrange(key, 0, -1, true).each_slice(2) do |key_value|
          value, key = key_value
          obj[key.to_s] = handle_value(value)
        end
      end
    rescue ::Redis::Error
      nil
    end

    private def handle_value(value : ::Redis::RedisValue) : Any
      Any.new(JSON.parse(value.to_s))
    rescue
      Any.new(casting(value))
    end

    private def casting(value : ::Redis::RedisValue)
      case value
      when Int32 then value.as(Int32)
      when Int64 then value.as(Int64)
      when String then value.as(String)
      when Array then casting(value)
      else            nil
      end
    end
  end
end

Totem::RemoteProviders.register_adapter("redis", Totem::RemoteProviders::Redis)
