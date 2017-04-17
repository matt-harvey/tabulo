# Tabulo

## Overview

Tabulo generates ASCII tables for displaying in a terminal or as preformatted text.

A `Tabulo::Table` can be printed:

```
> puts table
+----------+----------+
|     N    |  Doubled |
+----------+----------+
|        1 |        2 |
|        2 |        4 |
| 50000000 | 10000000 |
```

But it is also `Enumerable`, so you can process it one row at a time:

```ruby
table.each do |row|
  puts row
  # do some other thing that you want to do for each row
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tabulo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tabulo

## Usage

Require the gem:

```ruby
require 'tabulo'
```

Instantiate a `Tabulo::Table` by passing it an underlying `Enumerable` and then telling it
the columns you want to generate.

A simple case involves initializing columns from symbols corresponding to methods on members of the
`Enumerable`. In this case the symbol also provides the header for each column:

```ruby
table = Tabulo::Table.new([1, 2, 5]) do |t|
  t.add_column(:itself)
  t.add_column(:even?)
  t.add_column(:odd?)
end

# > puts table
# +----------+----------+----------+
# |  itself  |   even?  |   odd?   |
# +----------+----------+----------+
# |        1 |   false  |   true   |
# |        2 |   true   |   false  |
# |        5 |   false  |   true   |
```

Columns can also be initialized using blocks or procs that are called on each object. In this case
the first argument provides the column header:

```ruby
table = Tabulo::Table.new([1, 2, 5]) do |t|
  t.add_column("N", &:itself)
  t.add_column("Doubled") { |n| n * 2 }
end

# > puts table
# +----------+----------+
# |     N    |  Doubled |
# +----------+----------+
# |        1 |        2 |
# |        2 |        4 |
# |        5 |       10 |
```

TODO: Finish this...


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`, which
will create a git tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matt-harvey/tabulo.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

