module Fzy
  alias BonusFunction = Proc(String, Int32, Float32)

  def self.file_path_bonus(item : String, i : Int32) : Float32
    last_ch = i.zero? ? '/' : item[i - 1]
    ch = item[i]

    if last_ch == '/'
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
  end

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

    # Return true if haystack is empty.
    delegate empty?, to: @haystack
    # Return true if haystack has some item.
    delegate any?, to: @haystack

    # Creates a new `PreparedHaystack`.
    def initialize(@haystack : Array(String))
    end

    def search(needle : String) : Array(Match)
      return [] of Match if needle.empty?

      needle = needle.downcase

      matches = [] of Match
      @haystack.each_with_index do |haystack, index|
        next unless match?(needle, haystack)

        matches << Match.new(needle, haystack, ->Fzy.file_path_bonus(String, Int32), index)
      end
      matches.sort!
    end

    private def match?(lowercase_needle : String, haystack : String) : Bool
      offset = 0
      lowercase_needle.each_char do |nch|
        new_upcase_offset = haystack.index(nch.upcase, offset)
        new_downcase_offset = haystack.index(nch, offset)
        offset = if new_upcase_offset.nil?
                   return false if new_downcase_offset.nil?

                   new_downcase_offset + 1
                 elsif new_downcase_offset.nil?
                   new_upcase_offset + 1
                 else
                   Math.min(new_downcase_offset, new_upcase_offset) + 1
                 end
      end
      true
    end
  end
end
