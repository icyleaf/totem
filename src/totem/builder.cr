require "json"

module Totem
  annotation Field
  end

  module Builder
    @@config = Totem.new

    macro included
      def self.configure
        @@config.load!
        yield @@config
        new(@@config)
      end

      def self.configure
        @@config.load!
        new(@@config)
      end
    end

    macro build
      def self.config_paths(paths : Array(String))
        @@config.config_paths = paths
      end

      def self.config_name(name : String)
        @@config.config_name = name
      end

      def self.config_type(type : String)
        @@config.config_type = type
      end

      def self.key_delimiter(delimiter : String)
        @@config.key_delimiter = delimiter
      end

      def self.env_prefix(prefix : String)
        @@config.env_prefix = prefix
      end

      def self.env_prefix(prefix : String)
        @@config.env_prefix = prefix
      end

      def self.automatic_env(status : Bool)
        @@config.automatic_env = status
      end

      def self.automatic_env(env_prefix : String)
        @@config.automatic_env(env_prefix)
      end

      def self.debugging(status : Bool)
        @@config.debugging = status
      end

      {{ yield }}
    end

    def initialize(@config : Config)
      {% begin %}
        {% properties = {} of Nil => Nil %}
        {% for ivar in @type.instance_vars %}
          {% if ivar.id != "config".id %}
            {% ann = ivar.annotation(Totem::Field) %}
            puts {{ ivar.type.id.stringify }}
            {%
              cast = if ivar.type == String
                        "as_s"
                     elsif ivar.type == Int32
                        "as_i"
                      elsif ivar.type == Int64
                        "as_i64"
                      elsif ivar.type == Float64
                        "as_f"
                      elsif ivar.type == Bool
                        "as_bool"
                      elsif ivar.type == Nil
                        "as_nil"
                      elsif ivar.type == Array
                        "as_a"
                      elsif ivar.type == Hash
                        "as_h"
                      else
                        "as(#{ivar.type})"
                      end

              properties[ivar.id] = {
                type:        ivar.type,
                key:         ((ann && ann[:key]) || ivar).id.stringify,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                cast:        cast
              }
            %}
          {% end %}
        {% end %}

        {% for name, value in properties %}
          %found{name} = false
          %var{name} = nil
        {% end %}

        {% for name, value in properties %}
            if @config.has_key?({{ value[:key] }})
              %found{name} = true
              %var{name} = @config.get({{ value[:key] }})
            end
        {% end %}

        {% for name, value in properties %}
          {% unless value[:nilable] || value[:has_default] %}
            if %var{name}.nil? && !%found{name} && !::Union({{value[:type]}}).nilable?
              raise NotFoundConfigKeyError.new("Not found config: {{ name.id }}")
            end
          {% end %}

          {% if value[:nilable] %}
            {% if value[:has_default] != nil %}
              @{{name}} = %found{name} ? %var{name} : {{value[:default]}}
            {% else %}
              @{{name}} = %var{name}
            {% end %}
          {% elsif value[:has_default] %}
            @{{name}} = %var{name}.nil? ? {{value[:default]}} : %var{name}
          {% else %}
            @{{name}} = (%var{name}).not_nil!.{{value[:cast].id}}
          {% end %}
        {% end %}
      {% end %}
    end
  end
end
