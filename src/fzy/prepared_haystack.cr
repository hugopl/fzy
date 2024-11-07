# This class should be used if you plan to do more than one search on the same haystack.
#
# It's the same of doing `collection.map { |e| Hay.new(e) }`
#
# ```
# haystack = %w(dog cat bat tiger)
# prepared_haystack = PreparedHaystack.new(haystack)
# Fzy.search(prepared_haystack).each do |match|
#   puts "found #{match.value} with score #{match.score}"
# end
# ```
module Fzy
  class PreparedHaystack(T)
    getter haystack : Array(Hay(T))

    def initialize(haystack : Enumerable(T))
      @haystack = haystack.map do |item|
        Hay.new(item)
      end
    end
  end
end
