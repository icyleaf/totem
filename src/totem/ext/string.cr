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

  # Cast value to Bool type, return `Nil` if not matched rules.
  #
  # Here is the rules, string could be in any case:
  #
  # - "true"/"false": `true`/`false` with strict mode
  # - "true"/"t"/"yes"/"y"/"1": `true` without strict mode
  # - "false"/"f"/"no"/"n"/"0": `false` without strict mode
  #
  # ```
  # "true".to_bool               # => true
  # "false".to_bool              # => false
  # "yes".to_bool(strict: false) # => true
  # "n".to_bool(strict: false)   # => false
  # "1".to_bool(false)           # => true
  # ```
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
