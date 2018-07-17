class String
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

  def to_bool(strict = true) : Bool?
    return if empty?

    value = downcase
    if strict
      value == "true" ? true : (value == "false" ? false : nil)
    else
      if %w(true t yes y 1).includes?(value)
        true
      elsif %w(false f no n 0).includes?(value)
        false
      end
    end
  end
end
