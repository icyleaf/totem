module Totem
  module Exception
    # :nodoc:
    class Error < ::Exception; end

    class NotFoundConfigFileError < Error; end

    class NotFoundConfigKeyError < Error; end

    class UnsupportedConfigError < Error; end

    class MappingError < Error; end
  end

  {% for cls in Exception.constants %}
    # :nodoc:
    alias {{ cls.id }} = Exception::{{ cls.id }}
  {% end %}
end
