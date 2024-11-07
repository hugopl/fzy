require "./match"

module Fzy
  # A hay in haystack, where you try to find a needle.
  class Hay(T)
    # key used to match, always in lower case.
    getter key : String
    # Reference to the item this Hay represents.
    getter item : T
    # Match bonus, default to `Fzy.filepath_bonus`.
    getter bonus : Array(Float32)

    # Initializes a Hay with a *key*, a reference to a *item* and a match *bonus*.
    def initialize(item : T, key : String = item.to_s, @bonus = Fzy.filepath_bonus(key)) forall T
      @key = key.downcase
      @item = item
      raise ArgumentError.new("Bonus size mismatch.") if @bonus.size != key.size
    end

    # Returns a `Match(T)` if *downcase_needle* matches.
    #
    # To save some memory allocations the match doesn't save the matched character
    # positions, to change that pass true to *store_positions*.
    #
    # *downcase_needle* MUST be downcase for case insensitive search.
    def match?(downcase_needle : String, store_positions = false) : Match(T)?
      offset = 0
      downcase_needle.each_char do |nch|
        new_offset = @key.index(nch, offset)
        return if new_offset.nil?

        offset = new_offset + 1
      end
      Match(T).new(downcase_needle, self, store_positions)
    end
  end
end
