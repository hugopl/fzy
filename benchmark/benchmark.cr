require "benchmark"
require "../src/fzy"

haystack = File.read("./benchmark/data.txt").split("\n")

prepared_haystack = Fzy::PreparedHaystack.new(haystack)
Benchmark.ips do |x|
  x.report("bare search") { Fzy.search("main", haystack) }
  x.report("empty search") { Fzy.search("", haystack) }
  x.report("prepared search") { Fzy.search("main", prepared_haystack) }
  x.report("double prepared search") do
    Fzy.search("main", prepared_haystack)
    Fzy.search("MAIN", prepared_haystack)
  end
end
