require "./fzy/match"

module Fzy
  extend self

  VERSION = {{ `shards version #{__DIR__}`.strip.stringify }}

  # :nodoc:
  SCORE_MATCH_SLASH = 0.9_f32
  # :nodoc:
  SCORE_MATCH_WORD = 0.8_f32
  # :nodoc:
  SCORE_MATCH_CAPITAL = 0.7_f32
  # :nodoc:
  SCORE_MATCH_DOT = 0.6_f32

  # A bonus function is used to add more points to a match for whatever reason.
  #
  # The default bonus function
  alias BonusFunction = Proc(String, Int32, Float32)

  # File path based bonus function.
  # Increase the match score on a match after a slash, '-', '_' and ' ',
  # '.' or a upper case letter after a lower case one.
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

  # Search a needle in a haystack and returns an array of matches.
  #
  # ```
  # results = Fzy.search("hey", %w(Hey Halley Whatever))
  # results.each do |result|
  #   puts "value: #{result.value}"
  #   puts "score: #{result.score}"
  #   puts "  pos: #{result.positions.inspect}"
  # end
  # ```
  def search(needle : String, haystack : Enumerable(T), *,
             store_positions : Bool = false,
             bonus_func : BonusFunction? = nil, &block : T -> String?) : Array(Match(T)) forall T
    matches = [] of Match(T)
    return matches if needle.empty?

    lowercase_needle = needle.downcase
    haystack.each do |item|
      key = block.call(item)
      if key && Fzy.match?(lowercase_needle, key)
        matches << Match.new(lowercase_needle, key, bonus_func, store_positions, item)
      end
    end
    matches.sort!
  end

  def search(needle : String, haystack : Enumerable(T), *,
             store_positions : Bool = false,
             bonus_func : BonusFunction? = nil) : Array(Match(T)) forall T
    search(needle, haystack, store_positions: store_positions, bonus_func: bonus_func, &.to_s)
  end

  def search_file(needle : String, haystack : Enumerable(T), *,
                  store_positions : Bool = false) : Array(Match(T)) forall T
    search(needle, haystack, store_positions: store_positions, bonus_func: ->file_path_bonus(T, Int32), &.to_s)
  end

  protected def match?(lowercase_needle : String, haystack : String) : Bool
    offset = 0
    lowercase_needle.each_char do |nch|
      downcase_offset = haystack.index(nch, offset)
      upcase_offset = haystack.index(nch.upcase, offset)
      offset = if downcase_offset.nil?
                 return false if upcase_offset.nil?

                 upcase_offset
               elsif upcase_offset.nil?
                 downcase_offset
               else
                 Math.min(downcase_offset, upcase_offset)
               end
      offset += 1
    end
    true
  end
end
