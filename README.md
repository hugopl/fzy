# fzy.cr

[![Build Status](https://travis-ci.org/hugopl/fzy.svg?branch=master)](https://travis-ci.org/hugopl/fzy)

A Crystal port of awesome [Fzy](https://github.com/jhawthorn/fzy) fuzzy finder algorithm.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     fzy:
       github: hugopl/fzy
   ```

2. Run `shards install`

## Usage

```crystal
require "fzy"

results = Fzy.search("hey", %w(Hey Halley Whatever))
results.each do |result|
  puts "value: #{result.value}"
  puts "  pos: #{result.positions.inspect}"
end
```

Should print

```
value: Hey
  pos: [0, 1, 2]
value: Halley
  pos: [0, 4, 5]
```

`search` call should be enough for most of people, but there are some primitives in the API if you want to do something else.

```crystal
# Returns true if the needle matches haystack.
Fzy.match?(needle : String, haystack : String) : Bool

# Returns the scode of needle against haystack
# MatchComputation is a object used to share the computation between score and positions calls for the same
# needle and haystack.
#
# This method expects that needle matches the haystack.
Fzy.score(needle : String, haystack : String, computation : MatchComputation? = nil) : Float32

# Returns an array of needle.size size, each element is the position of the needle char at
# that index into haystack.
#
# This method expects that needle matches the haystack.
Fzy.positions(needle : String, haystack : String, computation : MatchComputation? = nil) : Array(Int32)
```

## Contributing

1. Fork it (<https://github.com/hugopl/fzy/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Hugo Parente Lima](https://github.com/hugopl) - creator and maintainer
