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

## TODO

Current version works and it's pretty fast, but common use case for fyz is to have the same _haystack_ and find for different _needles_,
so it's on my plans to improve the API a bit to avoid some double computation and save some allocations.

Options like "do not compute positions" should also appear in next versions.

Write some API documentation!

## Contributing

1. Fork it (<https://github.com/hugopl/fzy/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Hugo Parente Lima](https://github.com/hugopl) - creator and maintainer
