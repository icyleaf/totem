# This is a extension of `String`.
class String
  # Converts camelcase to snakecase(underscores) boundaries.
  #
  # ```
  # "totemAny".snakecase # => "totem_any"
  # ```
  def snakecase
    return self if empty?

    first = true
    String.build do |io|
      each_char do |char|
        if first
          io << char.downcase
        elsif char.ord >= 65 && char.ord <= 90
          io << '_' << char.downcase
        else
          io << char
        end

        first = false
      end
    end
  end
end
