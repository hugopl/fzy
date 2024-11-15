# fzy.cr

![Build Status](https://github.com/hugopl/fzy/actions/workflows/ci.yml/badge.svg?branch=main)

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

Basic usage:

```crystal
require "fzy"

matches = Fzy.search("hey", %w(Hey Whatever Halley), store_positions: true)
matches.each do |match|
  puts "value: #{match.item}"
  puts "score: #{match.score}"
  puts "  pos: #{match.positions.inspect}"
end
```

Should print

```
value: Hey
score: Infinity
  pos: [0, 1, 2]
value: Halley
score: 1.87
  pos: [0, 4, 5]
```

If you need to do many searches on the same set of data you can speed up things by
creating an `Fzy::PreparedHaystack` or an array of `Fzy::Hay`.

```crystal
require "fzy"

haystack = %w(Hey Halley Whatever)
prepared_haystack = Fzy::PreparedHaystack.new(haystack)
matches = Fzy.search("hey", prepared_haystack)
matches.each do |match|
  puts "value: #{match.item}"
  puts "score: #{match.score}"
  puts "  pos: #{match.positions.inspect}"
end

# Reusing the prepared haystack makes the search faster.
matches = Fzy.search("ho let's go!", prepared_haystack)
```

## Contributing

1. Fork it (<https://github.com/hugopl/fzy/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Hugo Parente Lima](https://github.com/hugopl) - creator and maintainer
