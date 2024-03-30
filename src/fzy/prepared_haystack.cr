module Fzy
  # This class should be used if you plan to do more than one search on the same haystack.
  # It just cache some stuff making following searches faster.
  #
  # ```
  # haystack = %w(dog cat bat tiger)
  # prepared_haystack = PreparedHaystack.new(haystack)
  # Fzy.search(prepared_haystack).each do |match|
  #   puts "found #{match.value} with score #{match.score}"
  # end
  # ```
  #
  # Usually you never need to use any methods from this object, just create it and call `Fzy.search`.
  #
  # NOTE: This class DO NOT dup the haystack it receive in the constructor, storing just a reference to it, so if you change it without creating another `PreparedHaystack` you are going to get a undefined behavior.
  class PreparedHaystack(T)
    # Return the same haystack used in the constructor
    getter haystack : Array(T)
    # Cached lowercase version of `haystack`.
    getter lower_haystack : Array(String)

    @bonus : Array(Array(Float32)?)

    # Return true if haystack is empty.
    delegate empty?, to: @haystack
    # Return true if haystack has some item.
    delegate any?, to: @haystack

    # Creates a new `PreparedHaystack`.
    def initialize(@haystack : Array(T))
      @lower_haystack = @haystack.map(&.to_s.downcase)
      @bonus = Array(Array(Float32)?).new(@haystack.size, nil)
    end

    # Return the cached bonus for a haystack at given index.
    def bonus(index) : Array(Float32)
      bonus = @bonus[index]?
      return bonus unless bonus.nil?

      @bonus[index] = precompute_bonus(@haystack[index].to_s)
    end

    private def precompute_bonus(haystack : String) : Array(Float32)
      # Which positions are beginning of words
      m = haystack.size
      match_bonus = Array(Float32).new(m)

      last_ch = '/'

      Array(Float32).new(m) do |i|
        ch = haystack[i]
        match_bonus = if last_ch == '/'
                        SCORE_MATCH_SLASH
                      elsif last_ch == '-' || last_ch == '_' || last_ch == ' '
                        SCORE_MATCH_WORD
                      elsif last_ch == '.'
                        SCORE_MATCH_DOT
                      elsif last_ch.lowercase? && ch.uppercase?
                        SCORE_MATCH_CAPITAL
                      else
                        0_f32
                      end
        last_ch = ch
        match_bonus
      end
    end

    def search(needle : String) : Array(Match(T))
      return [] of Match(T) if needle.empty?

      lower_needle = needle.downcase
      @haystack.each.with_index.compact_map do |item, index|
        lower_hay = @lower_haystack[index]
        next unless Fzy.match?(lower_needle, lower_hay)

        Match.new(needle, lower_needle, @haystack[index].to_s, lower_hay, bonus(index), item)
      end.to_a.sort!
    end
  end
end
