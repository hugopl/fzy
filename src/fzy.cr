require "./fzy/match"
require "./fzy/bonus"
require "./fzy/prepared_haystack"

module Fzy
  extend self

  VERSION = {{ `shards version #{__DIR__}`.strip.stringify }}

  # Search a needle in a haystack and returns an array of matches.
  #
  # Note: If you plan to redo the search several times, consider using `search(String, Enumerable(Hay(T))`
  #
  # ```
  # results = Fzy.search("hey", %w(Hey Halley Whatever), store_positions: true)
  # results.each do |result|
  #   puts "value: #{result.value}"
  #   puts "score: #{result.score}"
  #   puts "  pos: #{result.positions.inspect}"
  # end
  # ```
  def search(needle : String, haystack : Enumerable(String),
             *, store_positions : Bool = false) : Array(Match(String))
    downcase_needle = needle.downcase
    haystack.compact_map do |str|
      hay = Hay.new(str, str, filepath_bonus(str))
      hay.match?(downcase_needle, store_positions)
    end.sort!
  end

  def search(needle : String, haystack : Enumerable(Hay(T)),
             *, store_positions : Bool = false) : Array(Match(T)) forall T
    downcase_needle = needle.downcase
    haystack.compact_map(&.match?(downcase_needle, store_positions)).sort!
  end

  def search(needle : String, haystack : Array(Match(T)),
             *, store_positions : Bool = false) : Array(Match(T)) forall T
    downcase_needle = needle.downcase
    haystack.compact_map(&.hay.match?(downcase_needle, store_positions)).sort!
  end

  def search(needle : String, haystack : Fzy::PreparedHaystack(T),
             *, store_positions : Bool = false) : Array(Match(T)) forall T
    search(needle, haystack.haystack, store_positions: store_positions)
  end
end
