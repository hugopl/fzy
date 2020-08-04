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
  class PreparedHaystack
    # Return the same haystack used in the constructor
    getter haystack : Array(String)
    # Cached lowercase version of `haystack`.
    getter lower_haystack : Array(String)

    @empty_search_result : Array(Match)?
    @bonus : Array(Array(Float32)?)

    # Return true if haystack is empty.
    delegate empty?, to: @haystack
    # Return true if haystack has some item.
    delegate any?, to: @haystack

    # Creates a new `PreparedHaystack`.
    def initialize(@haystack : Array(String))
      @lower_haystack = @haystack.map(&.downcase)
      @bonus = Array(Array(Float32)?).new(@haystack.size, nil)
    end

    # Return the cached bonus for a haystack at given index.
    def bonus(index) : Array(Float32)
      bonus = @bonus[index]?
      return bonus unless bonus.nil?

      @bonus[index] = precompute_bonus(@haystack[index])
    end

    private def precompute_bonus(haystack) : Array(Float32)
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

    private def empty_search_result
      @empty_search_result ||= begin
        positions = [] of Int32
        @haystack.map_with_index { |needle, i| Match.new(needle, SCORE_MIN, positions, i) }
      end
    end

    def search(needle : String) : Array(Match)
      return empty_search_result if needle.empty?

      lower_needle = needle.downcase
      matches = [] of Match
      @lower_haystack.each_with_index do |lower_hay, index|
        next unless match?(lower_needle, lower_hay)

        matches << Match.new(needle, lower_needle, self, index)
      end
      matches.sort!
    end

    private def match?(needle : String, haystack : String) : Bool
      offset = 0
      needle.each_char do |nch|
        new_offset = haystack.index(nch, offset)
        return false if new_offset.nil?

        offset = new_offset + 1
      end
      true
    end
  end
end
