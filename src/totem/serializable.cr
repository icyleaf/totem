module Totem
  annotation Field
  end

  module Serializable
    annotation Options
    end

    macro included
      macro inherited
        def self.new(config : Totem::Config)
          super
        end
      end
    end

    def initialize(reader : Totem::Reader)
      {% begin %}
        {% properties = {} of Nil => Nil %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(Totem::Field) %}
          {%
            properties[ivar.id] = {
              type:        ivar.type,
              key:         ((ann && ann[:key]) || ivar).id.stringify,
              has_default: ivar.has_default_value?,
              default:     ivar.default_value,
              nilable:     ivar.type.nilable?,
            }
          %}
        {% end %}

        {% for key, value in properties %}
          if reader.has_key?({{ value[:key] }})
            any_value = reader.get({{ value[:key] }})
            puts {{ key.id.stringify }}
            puts {{ value[:type].id.stringify }}
            {% if value[:type] == String %}
              @{{ key.id }} = any_value.as_s
            {% elsif value[:type].id.stringify.includes?("Array") %}
              @{{ key.id }} = any_value.as_a
            {% end %}
          else
            {% if value[:has_default] %}
              @{{ key.id }} = {{ value[:default] }}
            {% elsif value[:nilable] %}
              @{{ key.id }} = nil
            {% else %}
              raise Error.new("Missing key")
            {% end %}
          end
        {% end %}
      {% end %}
    end
  end
end
