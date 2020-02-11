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
  puts "score: #{result.score}"
  puts "  pos: #{result.positions.inspect}"
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

## Contributing

1. Fork it (<https://github.com/hugopl/fzy/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Hugo Parente Lima](https://github.com/hugopl) - creator and maintainer
