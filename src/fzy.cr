require "./fzy/match"
require "./fzy/file_path_bonus"

module Fzy
  extend self

  VERSION = {{ `shards version #{__DIR__}`.strip.stringify }}

  # A bonus function is used to add more points to a match for whatever reason.
  #
  # The default bonus function
  alias BonusFunction = Proc(String, Int32, Float32)

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
             bonus_func : BonusFunction? = nil, &) : Array(Match(T)) forall T
    matches = [] of Match(T)
    return matches if needle.empty?

    lowercase_needle = needle.downcase
    haystack.each do |item|
      key = yield(item)
      next if key.nil? || !Fzy.match?(lowercase_needle, key)

      matches << Match.new(lowercase_needle, key, bonus_func, store_positions, item)
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
    search_file(needle, haystack, store_positions: store_positions, &.to_s)
  end

  def search_file(needle : String, haystack : Enumerable(T), *,
                  store_positions : Bool = false) : Array(Match(T)) forall T
    search(needle, haystack, store_positions: store_positions, bonus_func: ->file_path_bonus(String, Int32)) do |item|
      yield(item)
    end
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
