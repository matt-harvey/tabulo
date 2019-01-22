# Tabulo

[![Gem Version][GV img]][Gem Version]
[![Coverage Status][CS img]][Coverage Status]
[![Build Status][BS img]][Build Status]

## Overview

Tabulo generates ASCII tables.

```ruby
table = Tabulo::Table.new([1, 2, 50000000]) do |t|
  t.add_column("N", &:itself)
  t.add_column("Doubled") { |n| n * 2 }
end
```

```
> puts table
+--------------+--------------+
|       N      |    Doubled   |
+--------------+--------------+
|            1 |            2 |
|            2 |            4 |
|      5000000 |     10000000 |
```

While there are similar Ruby gems, such as [terminal-table](https://github.com/tj/terminal-table)
and [tty-table](https://github.com/piotrmurach/tty-table), Tabulo differs from these in various
ways.

Tabulo has also been ported to Crystal (with some modifications): see [Tablo](https://github.com/hutou/tablo).

## Features

* Set [fixed column widths](#fixed-column-widths), then either [wrap](#overflow-handling) or
  [truncate](#overflow-handling) the overflow.
* Alternatively, [shrinkwrap](#shrinkwrap) the table so that each column is just wide enough for its contents.
* Put an upper limit on total table width when shrinkwrapping, to
  [stop it overflowing your terminal horizontally](#max-table-width).
* Alignment of cell content is [configurable](#cell-alignment), but has helpful content-based defaults
  (numbers right, strings left).
* Headers are [repeatable](#repeating-headers).
* Newlines within cell content are correctly handled.
* A `Tabulo::Table` is an `Enumerable`, so you can [step through it](#enumerator) a row at a time,
  printing as you go, without waiting for the entire underlying collection to load.
* Each `Tabulo::Row` is also an `Enumerable`, providing access to the underlying cell values.
* Tabulate arbitrary `Enumberable`s: the underlying collection need not be an array.

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
table = Tabulo::Table.new([1, 2, 5], columns: %i[itself even? odd?])
```

```
> puts table
+--------------+--------------+--------------+
|    itself    |     even?    |     odd?     |
+--------------+--------------+--------------+
|            1 |     false    |     true     |
|            2 |     true     |     false    |
|            5 |     false    |     true     |
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
+--------------+--------------+--------------+
|       N      |    Doubled   |     odd?     |
+--------------+--------------+--------------+
|            1 |            2 |     true     |
|            2 |            4 |     false    |
|            5 |           10 |     true     |
```

<a name="cell-alignment"></a>
### Cell alignment

By default, column header text is center-aligned, while the content of each body cell is aligned
according to its data type. Numbers are right-aligned, text is left-aligned, and booleans (`false`
and `true`) are center-aligned. This can be customized by passing `:center`, `:left` or `:right` to
the `align_header` or `align_body` options of `add_column`, e.g.:

```ruby
table.add_column("Doubled", align_header: :left, align_body: :left) { |n| n * 2 }
```

### Column width, wrapping and truncation

<a name="fixed-column-widths"></a>
#### Configuring fixed widths

By default, column width is fixed at 12 characters, plus 1 character of padding on either side.
This can be adjusted on a column-by-column basis using the `width` option of `add_column`:

```ruby
table = Tabulo::Table.new([1, 2]) do |t|
  t.add_column(:itself, width: 6)
  t.add_column(:even?, width: 9)
end
```

```
> puts table
+--------+-----------+
| itself |   even?   |
+--------+-----------+
|      1 |   false   |
|      2 |    true   |
```

If you want to set the default column width for all columns of the table to something other
than 12, use the `column_width` option when initializing the table:

```ruby
table = Tabulo::Table.new([1, 2], columns: %i[itself even?], column_width: 6)
```

```
> puts table
+--------+--------+
| itself |  even? |
+--------+--------+
|      1 |  false |
|      2 |  true  |
```

Widths set for individual columns always override the default column width for the table.

Note the single character of padding either side of each column is not counted in the column width.
The amount of this padding can be configured for the table as a whole, using the `column_padding`
option passed to `Table.new`.

<a name="shrinkwrap"></a>
#### Automating column widths

Instead of setting column widths "manually", you can tell the table to sort out the widths
itself, so that each column is just wide enough for its header and contents (plus a character
of padding):

```ruby
table = Tabulo::Table.new([1, 2], columns: %i[itself even?])
table.shrinkwrap!
```

```
> puts table
+--------+-------+
| itself | even? |
+--------+-------+
|      1 | false |
|      2 |  true |
```

The `shrinkwrap!` method returns the table itself, so you can "wrap-and-print" in one go:

```ruby
puts Tabulo::Table.new([1, 2], columns: %i[itself even?]).shrinkwrap!
```

<a name="max-table-width"></a>
You can place an upper limit on the total width of the table when shrinkwrapping:

```ruby
puts Tabulo::Table.new([1, 2], columns: %i[itself even?]).shrinkwrap!(max_table_width: 17)
```

```
+-------+-------+
| itsel | even? |
| f     |       |
+-------+-------+
|     1 | false |
|     2 |  true |
```

If the table cannot be fit within `max_table_width`, column widths are reduced as required, with
wrapping or truncation then occuring as necessary (see [Overflow handling](#overflow-handling)).
Under the hood, a character of width is deducted column by column&mdash;the widest column being
targetted each time&mdash;until the table will fit. This is very useful when you want to ensure the
table will not overflow your terminal horizontally.

Note that shrinkwrapping necessarily involves traversing the entire collection up front as
the maximum cell width needs to be calculated for each column. You may not want to do this
if the collection is very large. Note also the effect of `shrinkwrap!` is to fix the column widths
as appropriate to the formatted cell contents given the state of the underlying collection
_at the point of shrinkwrapping_. If the underlying collection changes between that point, and when
the table is printed, then the columns will _not_ be resized yet again on printing. This is a
consequence of the table always being essentially a "live view" on the underlying collection:
formatted contents are never cached within the table itself.

<a name="overflow-handling"></a>
#### Overflow handling

By default, if cell contents exceed their column width, they are wrapped for as many rows as
required:

```ruby
table = Tabulo::Table.new(
  ["hello", "abcdefghijklmnopqrstuvwxyz"],
  columns: %i[itself length]
)
```

```
> puts table
+--------------+--------------+
|    itself    |    length    |
+--------------+--------------+
| hello        |            5 |
| abcdefghijkl |           26 |
| mnopqrstuvwx |              |
| yz           |              |
```

Wrapping behaviour is configured for the table as a whole using the `wrap_header_cells_to` option
for header cells and `wrap_body_cells_to` for body cells, both of which default to `nil`, meaning
that cells are wrapped to as many rows as required. Passing an `Integer` limits wrapping to the given
number of rows, with content truncated from that point on. The `~` character is appended to the
outputted cell content to show that truncation has occurred:

```ruby
table = Tabulo::Table.new(
  ["hello", "abcdefghijklmnopqrstuvwxyz"],
  wrap_body_cells_to: 1,
  columns: %i[itself length]
)
```

```
> puts table
+--------------+--------------+
|    itself    |    length    |
+--------------+--------------+
| hello        |            5 |
| abcdefghijkl~|           26 |
```

### Formatting cell values

While the callable passed to `add_column` determines the underyling, calculated value in each
cell of the column, there is a separate concept, of a "formatter", that determines how that value will
be visually displayed. By default, `.to_s` is called on the underlying cell value to "format"
it; however, you can format it differently by passing another callable to the `formatter` option
of `add_column`:

```ruby
table = Tabulo::Table.new(1..3) do |t|
  t.add_column("N", &:itself)
  t.add_column("Reciprocal", formatter: -> (n) { "%.2f" % n }) do |n|
    1.0 / n
  end
end
```

```
puts table
+--------------+--------------+
|       N      |  Reciprocal  |
+--------------+--------------+
|            1 |         1.00 |
|            2 |         0.50 |
|            3 |         0.33 |
```

Note the numbers in the "Reciprocal" column in this example are still right-aligned, even though
the callable passed to `formatter` returns a String. Default cell alignment is determined by the type
of the underlying cell value, not the way it is formatted. This is usually the desired result.

Note also that the item yielded to `.each` for each cell when enumerating over a `Tabulo::Row` is
the underlying value of that cell, not its formatted value.

<a name="repeating-headers"></a>
### Repeating headers

By default, headers are only shown once, at the top of the table (`header_frequency: :start`). If
`header_frequency` is passed `nil`, headers are not shown at all; or, if passed an `Integer` N,
headers are shown at the top and then repeated every N rows. This can be handy when you're looking
at table that's taller than your terminal.

E.g.:

```ruby
table = Tabulo::Table.new(1..10, columns: %i[itself even?], header_frequency: 5)
```

```
> puts table
+--------------+--------------+
|    itself    |     even?    |
+--------------+--------------+
|            1 |     false    |
|            2 |     true     |
|            3 |     false    |
|            4 |     true     |
|            5 |     false    |
+--------------+--------------+
|    itself    |     even?    |
+--------------+--------------+
|            6 |     true     |
|            7 |     false    |
|            8 |     true     |
|            9 |     false    |
|           10 |     true     |
```

<a name="enumerator"></a>
### Using a Table Enumerator

Because it's an `Enumerable`, a `Tabulo::Table` can also give you an `Enumerator`,
which is useful when you want to step through rows one at a time. In a Rails console,
for example, you might do this:

```
> e = Tabulo::Table.new(User.find_each) do |t|
  t.add_column(:id)
  t.add_column(:email, width: 24)
end.to_enum  # <-- make an Enumerator
...
> puts e.next
+--------------+--------------------------+
|      id      |          email           |
+--------------+--------------------------+
|            1 | jane@example.com         |
=> nil
> puts e.next
|            2 | betty@example.net        |
=> nil
```

Note the use of `.find_each`: we can start printing the table without having to load the entire
underlying collection. (This is negated if we [shrinkwrap](#shrinkwrap) the table, however, since
in that case the entire collection must be traversed up front in order for column widths to be
calculated.)

### Additional configuration options

The characters used for horizontal dividers, vertical dividers and corners, which default to `-`,
`|` and `+` respectively, can be configured using the using the `horizontal_rule_character`,
`vertical_rule_character` and `intersection_character` options passed to `Table.new`.

The character used to indicate truncation, which defaults to `~`, can be configured using the
`truncation_indicator` option passed to `Table.new`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matt-harvey/tabulo.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

[Gem Version]: https://rubygems.org/gems/tabulo
[Build Status]: https://travis-ci.org/matt-harvey/tabulo
[Coverage Status]: https://coveralls.io/r/matt-harvey/tabulo

[GV img]: https://img.shields.io/gem/v/tabulo.svg?style=plastic
[BS img]: https://img.shields.io/travis/matt-harvey/tabulo.svg?style=plastic
[CS img]: https://img.shields.io/coveralls/matt-harvey/tabulo.svg?style=plastic
