# Tabulo

[![Gem Version][GV img]][Gem Version]
[![Documentation][DC img]][Documentation]
[![Coverage Status][CS img]][Coverage Status]
[![Build Status][BS img]][Build Status]
[![Code Climate][CC img]][Code Climate]
[![Awesome][AR img]][Awesome Ruby]

Tabulo is a terminal table generator for Ruby.

It offers a DRY, "column-centric" interface, and is designed to make it very easy to produce highly
readable tables, even from large and unwieldy data sets and streams.

Tabulo is both easy to use and feature rich, allowing you to quickly tabulate any enumerable
collection, with options for automatic column sizing, a variety of border styles, and more.

```
> puts Tabulo::Table.new(User.all, :id, :first_name, :last_name, border: :modern).pack
┌────┬────────────┬───────────┐
│ id │ first_name │ last_name │
├────┼────────────┼───────────┤
│  1 │ John       │ Citizen   │
│  2 │ Jane       │ Doe       │
└────┴────────────┴───────────┘
```

## Features

* Lets you set [fixed column widths](#fixed-column-widths), then either [wrap](#overflow-handling)
  or [truncate](#overflow-handling) the overflow.
* Alternatively, ["pack"](#pack) the table so that each column is automatically just wide enough for
  its contents, but [without overflowing the terminal horizontally](#max-table-width).
* Alignment of cell content is [configurable](#cell-alignment), but has helpful content-based
  defaults (numbers right, strings left).
* Tabulate any `Enumerable`: the underlying collection need not be an array.
* Since a `Tabulo::Table` is itself also an `Enumerable`, you can [step through it](#enumerator) a
  row at a time, printing as you go, without waiting for the entire underlying collection to load.
  In other words, you get a [streaming interface](#enumerator) for free.
* Each `Tabulo::Row` is also an `Enumerable`, [providing access](#accessing-cell-values) to the
  underlying cell values.
* The header row can be [repeated](#repeating-headers) at arbitrary intervals.
* Newlines within cell content are correctly handled.
* Multibyte Unicode characters are correctly handled.
* Apply [colours](#colours-and-styling) and other styling to table content and borders, without breaking the table.
* Easily [transpose](#transposition) the table, so that rows are swapped with columns.
* Choose from multiple [border configurations](#borders), including Markdown, "ASCII", and smoothly joined Unicode border characters.
* Use a [DRY initialization interface](#configuring-columns): by being "column based", it is
  designed to spare the developer the burden of syncing the ordering within the header row with that of the body rows.

Tabulo has also been ported to Crystal (with some modifications): see [Tablo](https://github.com/hutou/tablo).

## Contents

  * [Features](#features)
  * [Table of contents](#table-of-contents)
  * [Installation](#installation)
  * [Detailed usage](#detailed-usage)
     * [Requiring the gem](#requiring-the-gem)
     * [Configuring columns](#configuring-columns)
     * [Cell alignment](#cell-alignment)
     * [Column width, wrapping and truncation](#column-width-wrapping-and-truncation)
        * [Configuring fixed widths](#configuring-fixed-widths)
        * [Configuring padding](#configuring-padding)
        * [Automating column widths](#automating-column-widths)
        * [Overflow handling](#overflow-handling)
     * [Formatting cell values](#formatting-cell-values)
     * [Colours and styling](#colours-and-styling)
     * [Repeating headers](#repeating-headers)
     * [Using a Table Enumerator](#using-a-table-enumerator)
     * [Accessing cell values](#accessing-cell-values)
     * [Accessing the underlying enumerable](#accessing-sources)
     * [Transposing rows and columns](#transposition)
     * [Border configuration](#borders)
     * [Row dividers](#dividers)
  * [Comparison with other libraries](#motivation)
  * [Contributing](#contributing)
  * [License](#license)

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
table = Tabulo::Table.new([1, 2, 5])
table.add_column(:itself)
table.add_column(:even?)
table.add_column(:odd?)
```

Alternatively, you can pass an initialization block to `new`:

```ruby
table = Tabulo::Table.new([1, 2, 5]) do |t|
  t.add_column(:itself)
  t.add_column(:even?)
  t.add_column(:odd?)
end
```

When the columns correspond to methods, you can also use the "quick API", by passing a symbol
directly to `new` for each column:

```ruby
table = Tabulo::Table.new([1, 2, 5], :itself, :even?, :odd?)
```

```
> puts table
+--------------+--------------+--------------+
|    itself    |     even?    |     odd?     |
+--------------+--------------+--------------+
|            1 |     false    |     true     |
|            2 |     true     |     false    |
|            5 |     false    |     true     |
+--------------+--------------+--------------+
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
+--------------+--------------+--------------+
```

<a name="cell-alignment"></a>
### Cell alignment

By default, column header text is center-aligned, while the content of each body cell is aligned
according to its data type. Numbers are right-aligned, text is left-aligned, and booleans (`false`
and `true`) are center-aligned.

This default behaviour can be set at the table level, by passing `:center`, `:left` or `:right`
to the `align_header` or `align_body` options when initializing the table:

```ruby
table = Tabulo::Table.new([1, 2], :itself, :even?, align_header: :left, align_body: :right)
```

The table-level alignment settings can be overridden for individual columns by
passing similarly-named options to `add_column`, e.g.:

```ruby
table.add_column("Doubled", align_header: :right, align_body: :left) { |n| n * 2 }
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
+--------+-----------+
```

If you want to set the default column width for all columns of the table to something other
than 12, use the `column_width` option when initializing the table:

```ruby
table = Tabulo::Table.new([1, 2], :itself, :even?, column_width: 6)
```

```
> puts table
+--------+--------+
| itself |  even? |
+--------+--------+
|      1 |  false |
|      2 |  true  |
+--------+--------+
```

Widths set for individual columns always override the default column width for the table.

<a name="configuring-padding"></a>
#### Configuring padding

The single character of padding either side of each column is not counted in the column width.
The amount of this extra padding can be configured for the table as a whole, using the `column_padding`
option passed to `Table.new`&mdash;the default value of this option being `1`.

Passing a single integer to this option causes the given amount of padding to be applied to each
side of each column. For example:

```ruby
table = Tabulo::Table.new([1, 2, 5], :itself, :even?, :odd?, column_padding: 0)
```

```
> puts table
+------------+------------+------------+
|   itself   |    even?   |    odd?    |
+------------+------------+------------+
|           1|    false   |    true    |
|           2|    true    |    false   |
|           5|    false   |    true    |
+------------+------------+------------+
```

Passing an array of _two_ integers to this option configures the left and right padding for each
column, according to the first and second element of the array, respectively. For example:

```ruby
table = Tabulo::Table.new([1, 2, 5], :itself, :even?, :odd?, column_padding: [0, 2])
```

```
> puts table
+--------------+--------------+--------------+
|   itself     |    even?     |    odd?      |
+--------------+--------------+--------------+
|           1  |    false     |    true      |
|           2  |    true      |    false     |
|           5  |    false     |    true      |
+--------------+--------------+--------------+
```

<a name="pack"></a>
#### Automating column widths

Instead of setting column widths "manually", you can tell the table to sort out the widths
itself, so that each column is just wide enough for its header and contents (plus a character
of padding):

```ruby
table = Tabulo::Table.new([1, 2], :itself, :even?)
table.pack
```

```
> puts table
+--------+-------+
| itself | even? |
+--------+-------+
|      1 | false |
|      2 |  true |
+--------+-------+
```

The `pack` method returns the table itself, so you can "pack-and-print" in one go:

```ruby
puts Tabulo::Table.new([1, 2], :itself, :even?).pack
```

<a name="max-table-width"></a>
You can manually place an upper limit on the total width of the table when packing:

```ruby
puts Tabulo::Table.new([1, 2], :itself, :even?).pack(max_table_width: 17)
```

```
+-------+-------+
| itsel | even? |
| f     |       |
+-------+-------+
|     1 | false |
|     2 |  true |
+-------+-------+
```

Or if you simply call `pack` with no arguments (or if you explicitly call
`pack(max_table_width: :auto)`), the table width will automatically be capped at the
width of your terminal.

If you want the table width not to be capped at all, call `pack(max_table_width: nil)`.

If the table cannot be fit within the width of the terminal, or the specified maximum width,
then column widths are reduced as required, with wrapping or truncation then occuring as
necessary (see [Overflow handling](#overflow-handling)). Under the hood, a character of width
is deducted column by column&mdash;the widest column being targetted each time&mdash;until
the table will fit.

Note that `pack`ing the table necessarily involves traversing the entire collection up front as
the maximum cell width needs to be calculated for each column. You may not want to do this
if the collection is very large. Note also the effect of `pack` is to fix the column widths
as appropriate to the formatted cell contents given the state of the underlying collection
_at the point of packing_. If the underlying collection changes between that point, and when
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
  :itself, :length
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
+--------------+--------------+
```

Wrapping behaviour is configured for the table as a whole using the `wrap_header_cells_to` option
for header cells and `wrap_body_cells_to` for body cells, both of which default to `nil`, meaning
that cells are wrapped to as many rows as required. Passing an `Integer` limits wrapping to the given
number of rows, with content truncated from that point on. The `~` character is appended to the
outputted cell content to show that truncation has occurred:

```ruby
table = Tabulo::Table.new(
  ["hello", "abcdefghijklmnopqrstuvwxyz"],
  :itself, :length,
  wrap_body_cells_to: 1
)
```

```
> puts table
+--------------+--------------+
|    itself    |    length    |
+--------------+--------------+
| hello        |            5 |
| abcdefghijkl~|           26 |
+--------------+--------------+
```

The character used to indicate truncation, which defaults to `~`, can be configured using the
`truncation_indicator` option passed to `Table.new`.

<a name="formatting-cell-values"></a>
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
> puts table
+--------------+--------------+
|       N      |  Reciprocal  |
+--------------+--------------+
|            1 |         1.00 |
|            2 |         0.50 |
|            3 |         0.33 |
+--------------+--------------+
```

Note the numbers in the "Reciprocal" column in this example are still right-aligned, even though
the callable passed to `formatter` returns a String. Default cell alignment is determined by the type
of the underlying cell value, not the way it is formatted. This is usually the desired result.

<a name="colours-and-styling"></a>
### Colours and styling

In most terminals, if you want to print text that is coloured, or has certain other styles such as
underlining, you need to use ANSI escape sequences, either directly, or by means of a library such
as [Rainbow](http://github.com/sickill/rainbow) that uses them internally. Tabulo needs to properly
account for escape sequences when performing the width calculations required to render tables.
The `styler` option on the `add_column` method is intended to facilitate this.

For example, suppose you have a table to which you want to add a column that
displays `true` in green if a given number is even, or else displays `false` in red.
You can achieve this as follows using raw ANSI escape codes:

```ruby
table.add_column(
  :even?,
  styler: -> (cell_value, s) { cell_value ? "\033[32m#{s}\033[0m" : "\033[31m#{s}\033[0m" }
)
```

Or, if you are using the [rainbow](https://github.com/sickill/rainbow) gem for colouring, you
could do the following:

```ruby
require "rainbow"

# ...

table.add_column(
  :even?,
  styler: -> (cell_value, s) { cell_value ? Rainbow(s).green : Rainbow(s).red }
)
```

The `styler` option should be passed a callable that takes two parameters: the
first represents the content of the cell (in this case a boolean indicating whether the
number is even); and the second represents the formatted string value of that cell, i.e. the
cell content after any processing by the [formatter](#formatting-cell-values).
If the content of a cell is wrapped over multiple lines, then the `styler` will be called
once per line, so that each line of the cell will have the escape sequence applied to it
separately (ensuring the styling doesn't bleed into neighbouring cells).

If you want to apply colours or other styling to the content of a column header, as opposed
to cells in the table body, use the `header_styler` option, e.g.:

```ruby
table.add_column(:even?, header_styler: -> (s) { "\033[32m#{s}\033[0m" })
```

To apply colours or other styling to the row divider, column divider, corner and border
characters of the table, use the `border_styler` option when initializing the table, e.g.:

```ruby
table = Tabulo::Table.new(1..5, :itself, :even?, :odd?, border_styler: -> (s) { "\033[32m#{s}\033[0m" })
```

If the content of a cell has been [truncated](#overflow-handling), then whatever colours or other styling
apply to the cell content will also be applied the truncation indicator character.

<a name="repeating-headers"></a>
### Repeating headers

By default, headers are only shown once, at the top of the table (`header_frequency: :start`). If
`header_frequency` is passed `nil`, headers are not shown at all; or, if passed an `Integer` N,
headers are shown at the top and then repeated every N rows. This can be handy when you're looking
at table that's taller than your terminal.

E.g.:

```ruby
table = Tabulo::Table.new(1..10, :itself, :even?, header_frequency: 5)
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
+--------------+--------------+
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
underlying collection. (This is negated if we [pack](#pack) the table, however, since
in that case the entire collection must be traversed up front in order for column widths to be
calculated.)

<a name="accessing-cell-values"></a>
### Accessing cell values

Each `Tabulo::Table` is an `Enumerable` of which each element is a `Tabulo::Row`. Each `Tabulo::Row`
is itself an `Enumerable`, of `Tabulo::Cell`. The `Tabulo::Cell#value` method will return the
underlying value of the cell; while `Tabulo::Cell#formatted_content` will return its formatted content
as a string.

A `Tabulo::Row` can also
be converted to a `Hash` for keyed access. For example:

```ruby
table = Tabulo::Table.new(1..3, :itself, :even?, :odd?)

table.each do |row|
  row.each { |cell| puts cell.value } # 1, false, true...2, true, false...3, false, true
  puts row.to_h[:even?].value         # false...true...false
end
```

The first argument to `add_column` always provides the key for the purpose of accessing the `Hash`
form of a `Tabulo::Row`. (If the provided argument was a `String`, it will be converted to a
`Symbol` for purposes of accessing this `Hash`.) This key serves as a sort of "logical label" for
the column; and it need not be the same as the column header. If we want the header to be different
to the label, we can achieve this using the `header` option to `add_column`:

```ruby
table = Tabulo::Table.new(1..3) do |t|
  t.add_column("Number") { |n| n }
  t.add_column(:doubled, header: "Number X 2") { |n| n * 2 }
end

table.each do |row|
  cells = row.to_h
  puts cells[:Number].value  # 1...2...3...
  puts cells[:doubled].value # 2...4...6...
end
```

<a name="accessing-sources"></a>
### Accessing the underlying enumerable

The underlying enumerable for a table can be retrieved by calling the `sources` getter:

```ruby
table = Tabulo::Table.new([1, 2, 5], :itself, :even?, :odd?)
```

```
> table.sources
=> [1, 2, 5]
```

There is also a corresponding setter, meaning you can reuse the same table to tabulate
a different data set, without having to reconfigure the columns and other options from scratch:

```ruby
table.sources = [50, 60]
```

```
> table.sources
=> [50, 60]
```

In addition, the element of the underlying enumerable corresponding to a particular
row can be accessed by calling the `source` method on that row:

```ruby
table.each do |row|
  puts row.source # 50...60...
end
```

<a name="transposition"></a>
### Transposing rows and columns

By default, Tabulo generates a table in which each row corresponds to a _record_, i.e. an element of
the underlying enumerable, and each column to a _field_. However, there are times when one instead
wants each row to represent a field, and each column a record. This is generally the case when there
are a small number or records but a large number of fields. To produce such a table, we can first
initialize an ordinary table, specifying fields as columns, and then call `transpose`, which returns
a new table in which the rows and columns are swapped:

```ruby
> puts Tabulo::Table.new(-1..1, :even?, :odd?, :zero?, :pred, :succ, :abs).transpose
```
```
+-------+--------------+--------------+--------------+
|       |      -1      |       0      |       1      |
+-------+--------------+--------------+--------------+
| even? |     false    |     true     |     false    |
|  odd? |     true     |     false    |     true     |
| zero? |     false    |     true     |     false    |
|  pred |           -2 |           -1 |            0 |
|  succ |            0 |            1 |            2 |
|   abs |            1 |            0 |            1 |
+-------+--------------+--------------+--------------+
```

By default, a header row is added to the new table, showing the string value of the element
represented in that column. This can be configured, however, along with other aspects of
`transpose`'s behaviour. For details, see the
[documentation](https://www.rubydoc.info/gems/tabulo/2.1.1/Tabulo/Table#transpose-instance_method).

<a name="borders"></a>
### Configuring borders

You can configure the kind of border and divider characters that are used when the table is printed.
This is done using the `border` option passed to `Table.new`. The options are as follows.

`:ascii`&mdash;this is the default; the table is drawn entirely with characters in the ASCII set:

```
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :ascii)
+--------------+--------------+--------------+
|    itself    |     even?    |     odd?     |
+--------------+--------------+--------------+
|            1 |     false    |     true     |
|            2 |     true     |     false    |
|            3 |     false    |     true     |
+--------------+--------------+--------------+
```

`:modern`&mdash;uses smoothly joined Unicode characters:

```
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :modern)
┌──────────────┬──────────────┬──────────────┐
│    itself    │     even?    │     odd?     │
├──────────────┼──────────────┼──────────────┤
│            1 │     false    │     true     │
│            2 │     true     │     false    │
│            3 │     false    │     true     │
└──────────────┴──────────────┴──────────────┘
```

`:markdown`&mdash;renders a GitHub flavoured Markdown table:

```
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :markdown)
|    itself    |     even?    |     odd?     |
|--------------|--------------|--------------|
|            1 |     false    |     true     |
|            2 |     true     |     false    |
|            3 |     false    |     true     |
```

`:blank`&mdash;no border or divider characters are printed:

```
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :blank)
    itself         even?         odd?     
            1      false         true     
            2      true          false    
            3      false         true     
```

`:reduced_ascii`&mdash;similar to `:ascii`, but without vertical lines:

```
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :reduced_modern)
-------------- -------------- --------------
    itself          even?          odd?     
-------------- -------------- --------------
            1       false          true     
            2       true           false    
            3       false          true     
-------------- -------------- --------------
```

`:reduced_modern`&mdash;similar to `:modern`, but without vertical lines:

```
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :reduced_ascii)
────────────── ────────────── ──────────────
    itself          even?          odd?     
────────────── ────────────── ──────────────
            1       false          true     
            2       true           false    
            3       false          true     
────────────── ────────────── ──────────────
```

`:classic`&mdash;reproduces the default behaviour in Tabulo v1; this is like the `:ascii` option,
but without a bottom border:

```
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :classic)
+--------------+--------------+--------------+
|    itself    |     even?    |     odd?     |
+--------------+--------------+--------------+
|            1 |     false    |     true     |
|            2 |     true     |     false    |
|            3 |     false    |     true     |
```

Note that, by default, none of the border options includes lines drawn _between_ rows in the body of the table.
These are configured via a separate option: see [below](#dividers).

<a name="dividers"></a>
### Row dividers

To add lines between rows in the table body, use the `row_divider_frequency` option when initializing
the table. The default value for this option is `nil`, meaning there are no dividing lines between
rows. But if this option passed is a positive integer N, then a dividing line is inserted before
every Nth row. For example:

```
> puts Tabulo::Table.new(1..6, :itself, :even?, :odd?, row_divider_frequency: 2)
+--------------+--------------+--------------+
|    itself    |     even?    |     odd?     |
+--------------+--------------+--------------+
|            1 |     false    |     true     |
|            2 |     true     |     false    |
+--------------+--------------+--------------+
|            3 |     false    |     true     |
|            4 |     true     |     false    |
+--------------+--------------+--------------+
|            5 |     false    |     true     |
|            6 |     true     |     false    |
+--------------+--------------+--------------+
```

If you want a line before every row, pass `1` to `row_divider_frequency`. For example:

```
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :modern, row_divider_frequency: 1)
┌──────────────┬──────────────┬──────────────┐
│    itself    │     even?    │     odd?     │
├──────────────┼──────────────┼──────────────┤
│            1 │     false    │     true     │
├──────────────┼──────────────┼──────────────┤
│            2 │     true     │     false    │
├──────────────┼──────────────┼──────────────┤
│            3 │     false    │     true     │
└──────────────┴──────────────┴──────────────┘
```

<a name="motivation"></a>
## Comparison with other libraries

There are other libraries for generating plain text tables in Ruby. Popular among these are:

* [terminal-table](https://github.com/tj/terminal-table)
* [tty-table](https://github.com/piotrmurach/tty-table)
* [table\_print](https://github.com/arches/table_print)
* [hirb](https://github.com/cldwalker/hirb)

*DISCLAIMER: My comments regarding these other libraries are based only on my own, possibly flawed
reading of the documentation for, and experimentation with, these libraries at the time of my
writing this. Their APIs, features or documentation may well change between when I write this, and
when you read it. Please consult the libraries' own documentation for yourself, rather than relying
on these comments.*

While these libraries have their strengths, I have personally found that, for the common use case of
printing a table on the basis of some underlying enumerable collection (such as an ActiveRecord
query result), using these libraries feels more cumbersome than it could be.

For example, suppose we have called `User.all` from the Rails console, and want to print
a table showing the email, first name, last name and ID of each user,
with column headings. Also, we want the ID column to be right-aligned, because it's a number.

In **terminal-table**, we could achieve this as follows:

```ruby
rows = User.all.map { |u| [u.email, u.first_name, u.last_name, u.id] }
headings = ["email", "first name", "last name", "id"]
table = Terminal::Table.new(headings: headings, rows: rows)
table.align_column(3, :right)
puts table
```

The problem here is that there is no single source of knowledge about which columns
appear, and in which order. If we want to add another column to the left of "email",
we need to amend the rows array, and the headings array, and the index passed to `align_column`.
We bear the burden of keeping these three in sync. This is not be a big deal for small one-off
tables, but for tables that have many columns, or that are constructed
dynamically based on user input or other runtime factors determining the columns
to be included, this can be a hassle and a source of brittleness.

**tty-table** has a somewhat different API to `terminal-table`. It offers both a
"row-based" and a "column-based" method of initializing a table. The row-based method
is similar to `terminal-table`'s in that it burdens the developer with syncing the
column ordering across multiple code locations. The "column-based" API for `tty-table`, on
the other hand, seems to avoid this problem. One way of using it is like this:

```ruby
users = User.all
table = TTY::Table.new [
  {
    "email" => users.map(&:email),
    "first name" => users.map(&:first_name),
    "last name" => users.map(&:last_name),
    "id" => users.map(&:id),
  }
]
puts table
```

While this doesn't seem too bad, it does mean that the underlying collection (`users`) has to
be traversed multiple times, once for each column, which is inefficient, particularly
if the underlying collection is large. In addition, it's not clear how to pass separate
formatting information for each column when initializing in this way. (Perhaps there is a way to do
this, but if there is, it doesn't seem to be documented.) So it seems we still have to use
`table.align_column(3, :right)`, which again burdens us with keeping the column index
passed to `align_column` in sync.

As for **table\_print**, this is a handy gem for quickly tabulating ActiveRecord
collections from the Rails console. `table_print` is similar to `tabulo` in that it has a
column-based API, so it doesn't suffer from the multiple-source-of-knowledge issue in regards to
column orderings. However, it lacks certain other useful features, such as the ability to repeat
headers every N rows, the automatic alignment of columns based on cell content (numbers right,
strings left), and a quick and easy way to automatically resize columns to accommodate cell content
without overflowing the terminal. Also, as of the time of writing, `table_print`'s last significant
commit (ignoring a deprecation warning fix in April 2018) was in March 2016.

Finally, it is worth mentioning the **hirb** library. This is similar to `table_print`, in that it's
well suited to quickly displaying ActiveRecord collections from the Rails console. However, like
`table_print`, there are certain useful features it's lacking; and using it outside the console
environment seems cumbersome. Moreover, it seems no longer to be maintained. At the time of writing,
its last commit was in March 2015.

<a name="contributing"></a>
## Contributing

Issues and pull requests are welcome on GitHub at https://github.com/matt-harvey/tabulo.

To start working on Tabulo, `git clone` and `cd` into your fork of the repo, then run `bin/setup` to
install dependencies.

`bin/console` will give you an interactive prompt that will allow you to experiment; and
`bundle exec rake spec` will run the test suite. For a list of other Rake tasks that are available in
the development environment, run `bundle exec rake -T`.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

[Gem Version]: https://rubygems.org/gems/tabulo
[Documentation]: http://www.rubydoc.info/gems/tabulo/2.1.1
[Build Status]: https://travis-ci.org/matt-harvey/tabulo
[Coverage Status]: https://coveralls.io/r/matt-harvey/tabulo
[Code Climate]: https://codeclimate.com/github/matt-harvey/tabulo
[Awesome Ruby]: https://github.com/markets/awesome-ruby#cli-utilities

[GV img]: https://img.shields.io/gem/v/tabulo.svg
[DC img]: https://img.shields.io/badge/documentation-v2.1.1-blue.svg
[BS img]: https://img.shields.io/travis/matt-harvey/tabulo.svg
[CS img]: https://img.shields.io/coveralls/matt-harvey/tabulo.svg
[CC img]: https://codeclimate.com/github/matt-harvey/tabulo/badges/gpa.svg
[AR img]: https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg
