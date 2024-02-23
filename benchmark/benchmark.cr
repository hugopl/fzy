require "benchmark"
require "../src/fzy"

haystack = File.read("./benchmark/data.txt").split("\n")

prepared_haystack = Fzy::PreparedHaystack.new(haystack)
Benchmark.ips do |x|
  x.report("bare search") do
    Fzy.search("main", haystack)
    Fzy.search("MAIN", haystack)
  end
  x.report("prepared search") do
    Fzy.search("main", prepared_haystack)
    Fzy.search("MAIN", prepared_haystack)
  end
end
