# croda

TODO: Write a description here

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     croda:
       github: matthewmcgarvey/croda
   ```

2. Run `shards install`

## Usage

```crystal
require "croda"
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## TODO

- Identify core plugins still missing
  - Plugin for showing available routes <https://github.com/jeremyevans/roda-route_list>
- Rename the project
  - I don't want this forever to be the "crystal version of Roda"
  - It can't live up to that anyways at very fundamental levels
  - Roda was originally named "Sinuba" which is simply a combination of Sinatra and Cuba (what Roda is forked from)
  - The name Roda is based on the trees in a video game series called Ys
- Write tests
- Write docs
- Compare performance between this and other common web frameworks
  - not to brag, but at a very base level, identify if performance is a tradeoff
  - I'm not sure I expect performance to be very different one way or the other

## Contributing

1. Fork it (<https://github.com/matthewmcgarvey/croda/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [your-name-here](https://github.com/matthewmcgarvey) - creator and maintainer
