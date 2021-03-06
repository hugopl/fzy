require "version_from_shard"

require "./fzy/match"
require "./fzy/prepared_haystack"

module Fzy
  extend self

  VersionFromShard.declare

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
  def search(needle : String, haystack : PreparedHaystack) : Array(Match)
    haystack.search(needle)
  end

  # Search a needle in a haystack and returns an array of matches.
  #
  # Consider using `search(String,PreparedHaystack)` if you want to repeat this call with
  # different needles but the same haystack.
  def search(needle : String, haystack : Array(String)) : Array(Match)
    search(needle, PreparedHaystack.new(haystack))
  end
end
