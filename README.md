# Tabulo

[![Gem Version][GV img]][Gem Version]
[![Build Status][BS img]][Build Status]

## Overview

Tabulo generates ASCII tables.

A `Tabulo::Table` can, of course, be printed:

```
> puts table
+----------+----------+
|     N    |  Doubled |
+----------+----------+
|        1 |        2 |
|        2 |        4 |
| 50000000 | 10000000 |
```

But it is also `Enumerable`, so you can process one row at a time:

```ruby
table.each do |row|
  puts row
  # do some other thing that you want to do for each row
end
```

And rows are themselves `Enumerable`, providing access to the underlying cell values:

```ruby
table.each do |row|
  row.each do |cell|
    # 1, 2, 50000000...
    puts cell.class  # Fixnum
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tabulo'
```

And then execute:

    $ bundle

Or install it yourself:

    $ gem install tabulo

## Detailed usage

### Requiring the gem

```ruby
require 'tabulo'
```

### Configuring columns

You instantiate a `Tabulo::Table` by passing it an underlying `Enumerable` and then telling it
the columns you want to generate.

A simple case involves initializing columns from symbols corresponding to methods on members of the
underlying `Enumerable`. In this case the symbol also provides the header for each column:

```ruby
table = Tabulo::Table.new([1, 2, 5]) do |t|
  t.add_column(:itself)
  t.add_column(:even?)
  t.add_column(:odd?)
end
```

Or equivalently:

```ruby
Tabulo::Table.new([1, 2, 5], columns: %i(itself even? odd?))
```

The resulting table looks like this:

```
> puts table
+----------+----------+----------+
|  itself  |   even?  |   odd?   |
+----------+----------+----------+
|        1 |   false  |   true   |
|        2 |   true   |   false  |
|        5 |   false  |   true   |
```

Columns can also be initialized using a callable to which each object will be passed to determine
the value to be displayed in the table. In this case, the first argument to `add_column` provides
the header text:

```ruby
table = Tabulo::Table.new([1, 2, 5]) do |t|
  t.add_column("N", &:itself)
  t.add_column("Doubled") { |n| n * 2 }
  t.add_column(:odd?)
end
```

```
> puts table
+----------+----------+----------+
|     N    |  Doubled |   odd?   |
+----------+----------+----------+
|        1 |        2 |   true   |
|        2 |        4 |   false  |
|        5 |       10 |   true   |
```

### Cell alignment

By default, column header text is center-aligned, while the content of each body cell is aligned
according to its data type. Numbers are right-aligned, text is left-aligned, and booleans (`false`
and `true`) are center-aligned. This can be customized by passing `:center`, `:left` or `:right` to
the `align_header` or `align_body` options of `add_column`, e.g.:

```ruby
  table.add_column("Doubled", align_header: :left, align_body: :left) { |n| n * 2 }
```

### Column width, wrapping and truncation

By default, column width is fixed at 8 characters, plus 1 character of padding on either side.
This can be customized using the `width` option of `add_column`:

```ruby
  table.add_column(:even?, width: 5)
```

### Overflow handling

By default, if cell contents exceed their column width, they are wrapped for as many rows as
required:

```ruby
table = Tabulo::Table.new(["hello", "abcdefghijklmnopqrstuvwxyz"], columns: %i(itself length))
```

```
> puts table
+----------+----------+
|  itself  |  length  |
+----------+----------+
| hello    |        5 |
| abcdefgh |       26 |
| ijklmnop |          |
| qrstuvwx |          |
| yz       |          |
```

Wrapping behaviour is configured for the table as a whole using the `wrap_header_cells_to` option
for header cells and `wrap_body_cells_to` for body cells, both of which default to `nil`, meaning
that cells are wrapped to as many rows as required. Passing a `Fixnum` limits wrapping to the given
number of rows, with content truncated from that point on. The `~` character is appended to the
outputted cell content to show that truncation has occurred:

```ruby
table = Tabulo::Table.new(["hello", "abcdefghijklmnopqrstuvwxyz"], wrap_body_cells_to: 1, columns: %i(itself length))
```

```
> puts table
+----------+----------+
|  itself  |  length  |
+----------+----------+
| hello    |        5 |
| abcdefgh~|       26 |
```

### Repeating headers

By default, headers are only shown once, at the top of the table (`header_frequency: :start`). If
`header_frequency` is passed `nil`, headers are not shown at all; or, if passed a `Fixnum` N,
headers are shown at the top and then repeated every N rows. This can be handy when you're looking
at table that's taller than your terminal.

E.g.:

```ruby
table = Tabulo::Table.new(1..10, columns: %i(itself even?), header_frequency: 5)
```

```
> puts table
+----------+----------+
|  itself  |   even?  |
+----------+----------+
|        1 |   false  |
|        2 |   true   |
|        3 |   false  |
|        4 |   true   |
|        5 |   false  |
+----------+----------+
|  itself  |   even?  |
+----------+----------+
|        6 |   true   |
|        7 |   false  |
|        8 |   true   |
|        9 |   false  |
|       10 |   true   |
```

TODO: Write rdocs, and link to them here "for more".

### Using a Table Enumerator

Because it's an `Enumerable`, a `Tabulo::Table` can also give you an `Enumerator`,
which is useful when you want to step through rows one at a time. In a Rails console,
for example, you might do this:

```
> e = Tabulo::Table.new(User.find_each) do |t|
  t.add_column(:id)
  t.add_column(:email, width: 25)
end.to_enum  # <-- make an Enumerator
...
> puts e.next
+----------+--------------------------+
|    id    |          email           |
+----------+--------------------------+
|        1 | jane@example.com         |
=> nil
> puts e.next
|        2 | betty@example.net        |
=> nil
```

Note the used of `.find_each`: we can start printing the table without having to load the entire
underlying collection. (The cost of supporting this behaviour is that Tabulo requires us to set
column widths up front, rather than adapting to the width of the widest value.)

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

[Gem Version]: https://rubygems.org/gems/tabulo
[Build Status]: https://travis-ci.org/matt-harvey/tabulo

[GV img]: https://badge.fury.io/rb/tabulo.png
[BS img]: https://travis-ci.org/matt-harvey/tabulo.png
