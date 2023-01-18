# Tabulo

[![Gem Version][GV img]][Gem Version]
[![Documentation][DC img]][Documentation]
[![Build Status][BS img]][Build Status]
[![Coverage Status][CS img]][Coverage Status]
[![Awesome][AR img]][Awesome Ruby]

Tabulo is a Ruby library for generating plain text tables, also known as &ldquo;ASCII tables&rdquo;. It is
both highly configurable and very easy to use.

<a name="overview"></a>
## Overview

_Quick API:_

```
> puts Tabulo::Table.new(User.all, :id, :first_name, :last_name).pack
+----+------------+-----------+
| id | first_name | last_name |
+----+------------+-----------+
|  1 | John       | Citizen   |
|  2 | Jane       | Doe       |
+----+------------+-----------+
```

_Full API:_

```
table = Tabulo::Table.new(User.all) do |t|
  t.add_column("ID", &:id)
  t.add_column("First name", &:first_name)
  t.add_column("Last name") { |user| user.last_name.upcase }
end
```

```
> puts table.pack
+----+------------+-----------+
| ID | First name | Last name |
+----+------------+-----------+
|  1 | John       | CITIZEN   |
|  2 | Jane       | DOE       |
+----+------------+-----------+
```

<a name="features"></a>
## Features

* Presents a [DRY API](#adding-columns) that is column-based, not row-based, meaning header and body rows are
  automatically in sync
* Lets you set [fixed column widths](#fixed-column-widths), then either [wrap](#overflow-handling)
  or [truncate](#overflow-handling) the overflow
* Alternatively, [&ldquo;pack&rdquo;](#pack) the table so that columns are auto-sized to their
  contents, but [without overflowing the terminal](#max-table-width)
* Cell alignment is [configurable](#cell-alignment), but has helpful content-based defaults (numbers right, strings
  left)
* Tabulate any `Enumerable`: the underlying collection need not be an array
* [Step through](#enumerator) your table a row at a time, printing as you go, without waiting for the
  underlying collection to load. In other words, have a [streaming interface](#enumerator) for free.
* Add an optional [title](#title) to your table
* The header row can be [repeated](#repeating-headers) at arbitrary intervals
* Newlines within cell content are correctly handled
* Multibyte Unicode characters are correctly handled
* Option to [preserve whole words](#preserve-words) when wrapping content
* Apply [colours](#colours-and-styling) and other styling to table content and borders, without breaking the table
* Easily [transpose](#transposition) the table, so that rows are swapped with columns
* Choose from multiple [border configurations](#borders), including Markdown, &ldquo;ASCII&rdquo;, and smoothly
  joined Unicode border characters

Tabulo has also been ported to Crystal (with some modifications): see [Tablo](https://github.com/hutou/tablo).

<a name="contents"></a>
## Contents

  * [Overview](#overview)
  * [Features](#features)
  * [Table of contents](#contents)
  * [Installation](#installation)
  * [Detailed usage](#detailed-usage)
     * [Creating a table](#table-initialization)
     * [Adding columns](#adding-columns)
        * [Quick API](#quick-api)
        * [Full API](#full-api)
        * [Column labels _vs_ headers](#labels-headers)
        * [Positioning columns](#column-positioning)
        * [Extracting column content from a hash or array](#from-arrays-hashes)
     * [Removing columns](#removing-columns)
     * [Adding a title](#title)
     * [Cell alignment](#cell-alignment)
     * [Column width, wrapping and truncation](#column-width-wrapping-and-truncation)
        * [Configuring fixed widths](#configuring-fixed-widths)
        * [Automating column widths](#automating-column-widths)
        * [Configuring padding](#configuring-padding)
        * [Overflow handling](#overflow-handling)
        * [Wrapping at word boundaries](#preserve-words)
        * [Manual cell wrapping](#manual-wrapping)
     * [Formatting cell values](#formatting-cell-values)
     * [Colours and other styling](#colours-and-styling)
        * [Styling cell content](#styling-cell-content)
        * [Styling column headers](#styling-column-headers)
        * [Styling the table title](#styling-title)
        * [Setting default styles](#default-styles)
        * [Styling borders](#styling-borders)
     * [Repeating headers](#repeating-headers)
     * [Using a Table Enumerator](#enumerator)
     * [Accessing cell values](#accessing-cell-values)
     * [Accessing the underlying enumerable](#accessing-sources)
     * [Transposing rows and columns](#transposition)
     * [Border configuration](#borders)
     * [Row dividers](#dividers)
     * [Using a table as a snapshot rather than as a dynamic view](#freezing-a-table)
  * [Comparison with other libraries](#motivation)
  * [Contributing](#contributing)
  * [License](#license)

<a name="installation"></a>
## Installation [&#x2191;](#contents)

Add this line to your application&#8217;s Gemfile:

```ruby
gem 'tabulo'
```

And then execute:

    $ bundle

Or install it yourself:

    $ gem install tabulo

To use the gem, you need to require it in your source code as follows:

```ruby
require 'tabulo'
```

<a name="detailed-usage"></a>
## Detailed usage [&#x2191;](#contents)

<a name="table-initialization"></a>
### Creating a table [&#x2191;](#contents)

You instantiate a `Tabulo::Table` by passing it an underlying `Enumerable`, being the collection of
things that you want to tabulate. Each member of this collection will end up
corresponding to a row of the table. The collection can be any `Enumerable`, for example a Ruby
`Array`, or an ActiveRecord relation:

```ruby
table = Tabulo::Table.new([1, 2, 5])
other_table = Tabulo::Table.new(User.all)
```

For the table to be useful, however, it must also contain columns&hellip;

<a name="adding-columns"></a>
### Adding columns [&#x2191;](#contents)

<a name="quick-api"></a>
#### Quick API [&#x2191;](#contents)

When the columns correspond to methods on members of the underlying enumerable, you can use
the &ldquo;quick API&rdquo;, by passing a symbol directly to `Tabulo::Table.new` for each column.
This symbol also provides the column header:

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

<a name="full-api"></a>
#### Full API [&#x2191;](#contents)

Columns can also be added to the table one-by-one using `add_column`. This &ldquo;full API&rdquo; is
more verbose, but provides greater configurability:

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

With the full API, columns can also be initialized using a callable to which each object will be
passed to determine the value to be displayed in the table. In this case, the first argument to
`add_column` provides the header text:

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

The `add_column` method can be passed a single parameter callable, as shown in the above example,
with the parameter representing the member of the underyling enumerable; or it can be passed
2-parameter callable, with the second parameter representing the (0-based) index of each row. This can be
useful if you want to display a row number in one of the columns:

```ruby
table = Tabulo::Table.new(["a", "b", "c"]) do |t|
  t.add_column("Row") { |letter, row_index| row_index }
  t.add_column("Value", &:itself)
end
```

```
> puts table
+--------------+--------------+
|      Row     |     Value    |
+--------------+--------------+
|            0 | a            |
|            1 | b            |
|            2 | c            |
+--------------+--------------+
```

<a name="labels-headers"></a>
#### Column labels _vs_ headers [&#x2191;](#contents)

The first argument to `add_column` is the called the _label_ for that column. It serves as the
column&#8217;s unique identifier: only one column may have a given label per table.
(`String`s and `Symbol`s are interchangeable for this purpose.) The label also forms the header shown
at the top of the column, unless a separate `header:` argument is explicitly passed:

```ruby
table.add_column(:itself, header: "N")
table.add_column(:itself2, header: "N", &:itself)  # header need not be unique
# table.add_column(:itself)  # would raise Tabulo::InvalidColumnLabelError, as label must be unique
```

<a name="column-positioning"></a>
#### Positioning columns [&#x2191;](#contents)

By default, each new column is added to the right of all the other columns so far added to the
table. However, if you want to insert a new column into some other position, you can use the
`before` option, passing the label of the column to the left of which you want the new column to be added:

```ruby
table = Tabulo::Table.new([1, 2, 3], :itself, :odd?)
table.add_column(:even?, before: :odd?)
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

<a name="from-arrays-hashes"></a>
#### Extracting column content from a hash or array [&#x2191;](#contents)

Sometimes the data source for the table may be a collection of hashes or arrays. For example:

```ruby
data = [
  { english: "hello", portuguese: "bom dia" },
  { english: "goodbye", portuguese: "adeus" },
]
```

or

```ruby
data = [
  ["hello", "bom dia"],
  ["goodbye", "adeus"],
]
```

To tabulate such a collection, simply use the same mechanism as described above, passing a block to
the `add_column` method to tell Tabulo how to extract the data for each column from a row. For
example, to tabulate the first example above, you could do something like this:

```ruby
table = Tabulo::Table.new(data) do |t|
  t.add_column("English") { |h| h[:english] }
  t.add_column("Portuguese") { |h| h[:portuguese] }
end

puts table
```

For the second example, you could do the following:

```ruby
table = Tabulo::Table.new(data) do |t|
  t.add_column("English") { |a| a[0] }
  t.add_column("Portuguese") { |a| a[1] }
end

puts table
```

In both cases, the output will be as follows:

```
+--------------+--------------+
|    English   |  Portuguese  |
+--------------+--------------+
| hello        | bom dia      |
| goodbye      | adeus        |
+--------------+--------------+
```

If you have previously used other terminal tabulation libraries, you may be accustomed to being _required_
to place your data into an array of hashes or arrays before you can tabulate them. Tabulo, however,
offers an API that is more general and flexible than this; your data source can be _any_
enumerable collection (not just an array), and each item in that collection can be _any_ object (not
necessarily an array or a hash). However, as shown above, it is still straightforward to tabulate an
array of hashes or arrays, if your data source happens to take that form.

<a name="removing-columns"></a>
### Removing columns [&#x2191;](#contents)

There is also a `#remove_column` method, for deleting an existing column from a table. Pass it
the label of the column you want to remove:

```ruby
table.remove_column(:even?)
```

<a name="title"></a>
### Adding a title [&#x2191;](#contents)

You can give your table a title, using the `title` option:

```ruby
table = Tabulo::Table.new([1, 2, 3], :itself, :even?, :odd?, title: "Numbers")
```

```
> puts table
+--------------------------------------------+
|                   Numbers                  |
+--------------+--------------+--------------+
|    itself    |     even?    |     odd?     |
+--------------+--------------+--------------+
|            1 |     false    |     true     |
|            2 |     true     |     false    |
|            3 |     false    |     true     |
+--------------+--------------+--------------+
```

There is a caveat: Using the `title` option with the `:markdown` [border type](#borders) will cause
the rendered table to cease being valid Markdown, as unfortunately almost no markdown engines support
adding a captions (i.e. titles) to tables.

<a name="cell-alignment"></a>
### Cell alignment [&#x2191;](#contents)

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

If a table title is present, it is center-aligned by default. This can be changed using the
`align_title` option when initializing the table:

```ruby
table = Tabulo::Table.new([1, 2], :itself, :even?, title: "Numbers", align_title: :left)
```

<a name="column-width-wrapping-and-truncation"></a>
### Column width, wrapping and truncation [&#x2191;](#contents)

<a name="fixed-column-widths"></a>
<a name="configuring-fixed-widths"></a>
#### Configuring fixed widths [&#x2191;](#contents)

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

<a name="pack"></a>
<a name="automating-column-widths"></a>
#### Automating column widths [&#x2191;](#contents)

Instead of setting column widths &ldquo;manually&rdquo;, you can tell the table to sort out the widths
itself, so that each column is just wide enough for its header and contents (plus a character
of padding on either side):

```ruby
table = Tabulo::Table.new(["short", "here is a longer phrase"], :itself, :size)
table.pack
```

```
> puts table
+-------------------------+------+
|          itself         | size |
+-------------------------+------+
| short                   |    5 |
| here is a longer phrase |   23 |
+-------------------------+------+
```

If the table [title](#title) happens to be too long to for the existing width of the table, `pack`
will also arrange for the table to be widened sufficiently to accommodate it without wrapping:

```ruby
table = Tabulo::Table.new(["a", "b"], :itself, :size, title: "Here are some letters of the alphabet")
table.pack
```

```
> puts table
+---------------------------------------+
| Here are some letters of the alphabet |
+-------------------+-------------------+
|       itself      |        size       |
+-------------------+-------------------+
| a                 |                 1 |
| b                 |                 1 |
+-------------------+-------------------+
```

The `pack` method returns the table itself, so you can &ldquo;pack-and-print&rdquo; in one go:

```ruby
puts Tabulo::Table.new(["short", "here is a longer phrase"], :itself, :size).pack
```

<a name="max-table-width"></a>
You can manually place an upper limit on the total width of the table when packing:

```ruby
puts Tabulo::Table.new(["short", "here is a longer phrase"], :itself, :size).pack(max_table_width: 24)
```

```
+---------------+------+
|     itself    | size |
+---------------+------+
| short         |    5 |
| here is a lon |   23 |
| ger phrase    |      |
+---------------+------+
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

To resize only specific columns, `pack` takes an `except:` argument, which can be a single column
label or an Array of column labels. E.g. `pack(except: :id)` will exclude the `id` column from
resizing and let it keep its current width. This is useful if you want to prevent the addition of
linebreaks in your data. When using this option, other columns might be shrunk more to still make
the table fit within the `max_table_width`.

For even finer-grained control over column and table resizing, see the
for the [`#autosize_columns`](https://www.rubydoc.info/gems/tabulo/2.8.2/Tabulo/Table#autosize_columns-instance_method)
and [`#shrink_to`](https://www.rubydoc.info/gems/tabulo/2.8.2/Tabulo/Table#shrink_to-instance_method) methods.

Note that `pack`ing the table necessarily involves traversing the entire collection up front as
the maximum cell width needs to be calculated for each column. You may not want to do this
if the collection is very large.

Note also the effect of `pack` is to fix the column widths as appropriate to the formatted cell
contents given the state of the underlying collection _at the point of packing_. If the underlying
collection changes between that point, and when the table is printed, then the columns will _not_ be
resized yet again on printing. This is a consequence of the table always being essentially a
&ldquo;live view&rdquo; on the underlying collection: formatted contents are never cached within the
table itself. There are [ways around this](#freezing-a-table), however, if this is not the desired
behaviour&mdash;see [below](#freezing-a-table).

<a name="configuring-padding"></a>
#### Configuring padding [&#x2191;](#contents)

The single character of padding either side of each column is not counted in the column width.
The amount of this extra padding can be configured for the table as a whole, using the `column_padding`
option passed to `Table.new`&mdash;the default value of this option being `1`.

Passing a single integer to this option causes the given amount of padding to be applied to each
side of each column. For example:

```ruby
table = Tabulo::Table.new([1, 2, 5], :itself, :even?, :odd?, column_padding: 0)
```

```
> puts table.pack
+------+-----+-----+
|itself|even?| odd?|
+------+-----+-----+
|     1|false| true|
|     2| true|false|
|     5|false| true|
+------+-----+-----+
```

Passing an array of _two_ integers to this option configures the left and right padding for each
column, according to the first and second element of the array, respectively. For example:

```ruby
table = Tabulo::Table.new([1, 2, 5], :itself, :even?, :odd?, column_padding: [0, 2])
```

```
> puts table.pack
+--------+-------+-------+
|itself  |even?  | odd?  |
+--------+-------+-------+
|     1  |false  | true  |
|     2  | true  |false  |
|     5  |false  | true  |
+--------+-------+-------+
```

Note how the padding amount is completely unaffected by the call `pack`.

Padding can also be configured on a column-by-column basis, using the `padding` option when calling
`add_column`:

```ruby
table = Tabulo::Table.new([1, 2, 5], :itself, :even?)
table.add_column(:odd?, padding: 3)
```

```
> puts table.pack
+--------+-------+-----------+
| itself | even? |    odd?   |
+--------+-------+-----------+
|      1 | false |    true   |
|      2 |  true |   false   |
|      5 | false |    true   |
+--------+-------+-----------+
```

This column-level `padding` setting always overrides any table-level `column_padding` setting, for
the column in question.

<a name="overflow-handling"></a>
#### Overflow handling [&#x2191;](#contents)

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

<a name="preserve-words"></a>
#### Wrapping at word boundaries [&#x2191;](#contents)

By passing `:word` to the `wrap_preserve` option on either table initialization (for all columns),
or when calling `add_column` (for an individual column), whole words can be preserved when wrapping:

```ruby
sentences = [
  "Words are preserved.",
  "Excessively long words may still be split to fit into the configured column width.",
]
table = Tabulo::Table.new(sentences, :itself, :length, column_width: 10, wrap_preserve: :word)
```

```
> puts table
+------------+------------+
|   itself   |   length   |
+------------+------------+
| Words are  |         20 |
| preserved. |            |
| Excessivel |         82 |
| y long     |            |
| words may  |            |
| still be   |            |
| split to   |            |
| fit into   |            |
| the        |            |
| configured |            |
| column     |            |
| width.     |            |
+------------+------------+
```

When wrapping cell content, Tabulo will never insert hyphens itself, although it will recognize existing
hyphens, m-dashes and n-dashes as word boundaries.

The `wrap_preserve` option defaults to the value `:rune`, meaning by default it will _not_ respect word
boundaries when wrapping (although it will always preserve whole multibyte Unicode characters).

<a name="manual-wrapping"></a>
#### Manual cell wrapping [&#x2191;](#contents)

You can &ldquo;manually&rdquo; wrap the content of a title, header or body cell at a particular
point, simply by placing a newline character, at that point:

```ruby
table = Tabulo::Table.new(1..3) do |t|
  t.add_column("The number\nitself", &:itself)
  t.add_column("Even?", &:even?)
  t.add_column("Odd?", &:odd?)
end
```

```
> puts table
+--------------+--------------+--------------+
|  The number  |     Even?    |     Odd?     |
|    itself    |              |              |
+--------------+--------------+--------------+
|            1 |     false    |     true     |
|            2 |     true     |     false    |
|            3 |     false    |     true     |
+--------------+--------------+--------------+
```

Tabulo will treat any of the character combinations `"\n"`, `"\r\n"` or `"\r"` equally, as a line break,
regardless of the platform it&#8217;s currently being run on. This ensures things are formatted as
expected if, for example, you are examining content that was produced on another platform from
the one you&#8217;re running Tabulo on.

<a name="formatting-cell-values"></a>
### Formatting cell values [&#x2191;](#contents)

While the callable passed to `add_column` determines the underyling, calculated value in each
cell of the column, there is a separate concept, of a &ldquo;formatter&rdquo;, that determines how
that value will be visually displayed. By default, `.to_s` is called on the underlying cell value to
&ldquo;format&rdquo; it; however, you can format it differently by passing another callable to the
`formatter` option of `add_column`:

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

Note the numbers in the &ldquo;Reciprocal&rdquo; column in this example are still right-aligned, even though
the callable passed to `formatter` returns a String. Default cell alignment is determined by the type
of the underlying cell value, not the way it is formatted. This is usually the desired result.

If you want to set the default formatter for all columns of the table to something other than
`#to_s`, use the `formatter` option when initializing the table:

```ruby
table = Tabulo::Table.new(1..3, formatter: -> (n) { "%.2f" % n }) do |t|
  t.add_column("N", &:itself)
  t.add_column("Reciprocal") { |n| 1.0 / n }
  t.add_column("Half") { |n| n / 2.0 }
end
```

```
> puts table
+--------------+--------------+--------------+
|       N      |  Reciprocal  |     Half     |
+--------------+--------------+--------------+
|         1.00 |         1.00 |         0.50 |
|         2.00 |         0.50 |         1.00 |
|         3.00 |         0.33 |         1.50 |
+--------------+--------------+--------------+
```

Formatters set for individual columns on calling `#add_column` always override the default formatter for
the table.

The `formatter` callback also has an alternative, 2-parameter version. If `formatter` is passed
a 2-parameter callable, the second parameter will be given a `CellData` instance,
containing additional information about the cell that may be useful in determining how to format
it&mdash;see the [documentation](https://www.rubydoc.info/gems/tabulo/2.8.2/Tabulo/CellData.html)
for details.

<a name="colours-and-styling"></a>
### Colours and other styling [&#x2191;](#contents)

<a name="styling-cell-content"></a>
#### Styling cell content [&#x2191;](#contents)

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

The `styler` option should be passed a callable that takes either 2, 3 or 4 parameters.
The first parameter represents the underlying value of the cell (in this case a boolean indicating whether the
number is even). The second parameter represents the formatted string value of that cell, i.e. the cell
content after any processing by the [formatter](#formatting-cell-values). The third and fourth
parameters are optional, and contain further information about the cell and its contents that may be useful in
determining how to style it. See the
[documentation](https://www.rubydoc.info/gems/tabulo/2.8.2/Tabulo/Table#add_column-instance_method) for details.

If the content of a cell is wrapped over multiple lines, then the `styler` will be called once
per line, so that each line of the cell will have the escape sequence applied to it separately
(ensuring the styling doesn&#8217;t bleed into neighbouring cells).

If the content of a cell has been [truncated](#overflow-handling), then whatever colours or other
styling apply to the cell content will also be applied the truncation indicator character.

<a name="styling-column-headers"></a>
#### Styling column headers [&#x2191;](#contents)

If you want to apply colours or other styling to the content of a column header, as opposed
to cells in the table body, use the `header_styler` option, e.g.:

```ruby
table.add_column(:even?, header_styler: -> (s) { "\033[32m#{s}\033[0m" })
```

The `header_styler` option accepts a 1-, 2- or 3-parameter callable. See the
[documentation](https://www.rubydoc.info/gems/tabulo/2.8.2/Tabulo/Table#add_column-instance_method)
for details.

<a name="styling-title"></a>
#### Styling the table title [&#x2191;](#contents)

To apply colours or other styling to the table title, if present, use the `title_styler` option
when initializing the table. This accepts a single-parameter callable:

```ruby
table = Tabulo::Table.new(1..5, :itself, :even?, :odd?, title: "Numbers", title_styler: -> (s) { "\033[32m#{s}\033[0m" })
```

The `title_styler` option accepts a 1- or 2-parameter callable. See the
[documentation](https://www.rubydoc.info/gems/tabulo/2.8.2/Tabulo/Table#initialize-instance_method)
for details.

<a name="styling-borders"></a>
#### Styling borders [&#x2191;](#contents)

Styling can also be applied to borders and dividing lines, using the `border_styler` option when
initializing the table, e.g.:

```ruby
table = Tabulo::Table.new(1..5, :itself, :even?, :odd?, border_styler: -> (s) { "\033[32m#{s}\033[0m" })
```

<a name="default-styles"></a>
#### Setting default styles [&#x2191;](#contents)

By default, no styling is applied to the headers or body content of a column unless configured to do
so via the `header_styler` or `styler` option when calling `add_column` for that particular column.
It is possible to apply styling by default to _all_ columns in a table, however, as the table initializer
also accepts both a `header_styler` and a `styler` option. For example, if you want all the header text
in the table to be green, you could do:

```ruby
table = Tabulo::Table.new(1..5, :itself, :even?, :odd?, header_styler: -> (s) { "\033[32m#{s}\033[0m" })
```

Now, all columns in the table will automatically have green header text, unless overridden by another
header styler being passed to `#add_column`.

<a name="repeating-headers"></a>
### Repeating headers [&#x2191;](#contents)

By default, headers are only shown once, at the top of the table (`header_frequency: :start`). If
`header_frequency` is passed `nil`, headers are not shown at all; or, if passed an `Integer` N,
headers are shown at the top and then repeated every N rows. This can be handy when you&#8217;re looking
at table that&#8217;s taller than your terminal.

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

Note that if the table has a [title](#title), it will not be repeated; only column headers are repeated.

One can achieve even finer-grained control over printing of headers within the table body by stepping
through the table a row at a time (using `.each` or other methods of `Enumerable`) and calling the
the [`formatted_header`](https://www.rubydoc.info/gems/tabulo/Tabulo/Table#formatted_header-instance_method)
method in combination with [`horizontal_rule`](https://www.rubydoc.info/gems/tabulo/Tabulo%2FTable:horizontal_rule)
to produce headers at arbitrary points in the output.

<a name="enumerator"></a>
### Using a Table Enumerator [&#x2191;](#contents)

Because it&#8217;s an `Enumerable`, a `Tabulo::Table` can also give you an `Enumerator`,
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
### Accessing cell values [&#x2191;](#contents)

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

The column label (being the first argument that was passed to `add_column`, converted if necessary
to a `Symbol`), always forms the key for the purposes of this `Hash`:

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
### Accessing the underlying enumerable [&#x2191;](#contents)

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
### Transposing rows and columns [&#x2191;](#contents)

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
`transpose`&#8217;s behaviour. For details, see the
[documentation](https://www.rubydoc.info/gems/tabulo/2.8.2/Tabulo/Table#transpose-instance_method).

<a name="borders"></a>
### Configuring borders [&#x2191;](#contents)

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

> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :ascii, title: "Numbers")
+--------------------------------------------+
|                   Numbers                  |
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

> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :modern, title: "Numbers")
┌────────────────────────────────────────────┐
│                   Numbers                  │
├──────────────┬──────────────┬──────────────┤
│    itself    │     even?    │     odd?     │
├──────────────┼──────────────┼──────────────┤
│            1 │     false    │     true     │
│            2 │     true     │     false    │
│            3 │     false    │     true     │
└──────────────┴──────────────┴──────────────┘
```

_Note: The unicode characters used for the `:modern` border may not render properly
when viewing this documentation on some browsers or devices. This doesn&#8217;t reflect any brokenness
in `tabulo` itself._

`:markdown`&mdash;renders a GitHub flavoured Markdown table:

```
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :markdown)
|    itself    |     even?    |     odd?     |
|--------------|--------------|--------------|
|            1 |     false    |     true     |
|            2 |     true     |     false    |
|            3 |     false    |     true     |

> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :markdown, title: "Numbers")
|                   Numbers                  |
|    itself    |     even?    |     odd?     |
|--------------|--------------|--------------|
|            1 |     false    |     true     |
|            2 |     true     |     false    |
|            3 |     false    |     true     |
```

_However_, note that when a table is rendered using the `:markdown` border type in combination with a
(non-`nil`) `title`, the result will be _invalid Markdown_. This is because Markdown engines do not
generally support adding a caption (i.e. title) element to tables.

`:blank`&mdash;no border or divider characters are printed:

```
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :blank)
    itself         even?         odd?     
            1      false         true     
            2      true          false    
            3      false         true     


> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :blank, title: "Numbers")
                  Numbers                 
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

> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :reduced_modern, title: "Numbers")
--------------------------------------------
                   Numbers                  
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

> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :reduced_ascii, title: "Numbers")
────────────────────────────────────────────
                   Numbers                  
────────────── ────────────── ──────────────
    itself          even?          odd?     
────────────── ────────────── ──────────────
            1       false          true     
            2       true           false    
            3       false          true     
────────────── ────────────── ──────────────
```

_Note: The unicode characters used for the `:reduced_modern` border may not render properly
when viewing this documentation on some browsers or devices. This doesn&#8217;t reflect any brokenness
in `tabulo` itself._

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

> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, border: :classic, title: "Numbers")
+--------------------------------------------+
|                   Numbers                  |
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
### Row dividers [&#x2191;](#contents)

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
> puts Tabulo::Table.new(1..3, :itself, :even?, :odd?, row_divider_frequency: 1)
+--------------+--------------+--------------+
|    itself    |     even?    |     odd?     |
+--------------+--------------+--------------+
|            1 |     false    |     true     |
+--------------+--------------+--------------+
|            2 |     true     |     false    |
+--------------+--------------+--------------+
|            3 |     false    |     true     |
+--------------+--------------+--------------+
```

In addition to these options, it is also possible to print horizontal dividers at any chosen
point in the table output, by stepping through the table one row at a time
and calling the [`horizontal_rule`](https://www.rubydoc.info/gems/tabulo/Tabulo%2FTable:horizontal_rule)
method as required.

<a name="freezing-a-table"></a>
### Using a table as a snapshot rather than as a dynamic view [&#x2191;](#contents)

The nature of a `Tabulo::Table` is that of a dynamic view onto the underlying `sources` enumerable
from which it was initialized (or which was subsequently assigned to its `sources` attribute). That
is, if the contents of the `sources` enumerable change subsequent to initialization of or assignment to
`sources`, then the table when printed will show the `sources` as they are at the time of printing,
not as they were at the time of initialization or assignment. For example:

```ruby
arr = [1, 2]
table = Tabulo::Table.new(arr, :itself, :even?, :odd?)
```

```
> puts table
+--------------+--------------+--------------+
|    itself    |     even?    |     odd?     |
+--------------+--------------+--------------+
|            1 |     false    |     true     |
|            2 |     true     |     false    |
+--------------+--------------+--------------+
```

```ruby
arr << 3
```

```
> puts table
+--------------+--------------+--------------+
|    itself    |     even?    |     odd?     |
+--------------+--------------+--------------+
|            1 |     false    |     true     |
|            2 |     true     |     false    |
|            3 |     false    |     true     |
+--------------+--------------+--------------+
```

In this example, even though no direct mutations have been made to `table`, the result
of calling `puts table` has changed, in virtue of a mutation on the underyling enumerable `arr`.

A similar behaviour can be seen when `sources` is an ActiveRecord query, and there
are changes to the relevant database table(s) such that the result of the query changes. This is
worth bearing in mind when calling [`pack`](#pack) on a table, since if the `sources` enumerable
changes between `pack`ing and printing, then the column widths calculated by the `pack` method
may no longer be &ldquo;just right&rdquo; given the changed `sources`.

If this is not the desired behaviour, there are ways around this. For example, if dealing with an
ActiveRecord relation, you can convert the query to a plain array before initializing the table:

```ruby
sources = User.all.to_a
table = Tabulo::Table.new(sources, :id, :first_name, :last_name)
table.pack
puts table
```

Passing an `Array` rather than the ActiveRecord query directly means that if there are changes to
the content of the `users` database table, these will not be reflected in the rendered content of
the `Tabulo::Table` (unless some of the `Tabulo::Table` columns are based on callables that perform
further database queries when called&hellip;).

Note that it is also possible simply to store the string value of a table for later use,
rather than the table itself:

```ruby
rendered_table = Tabulo::Table.new(1..10, :itself, :even?, :odd?).pack.to_s
```

<a name="motivation"></a>
## Comparison with other libraries [&#x2191;](#contents)

There are other libraries for generating plain text tables in Ruby. Popular among these are:

* [terminal-table](https://github.com/tj/terminal-table)
* [tty-table](https://github.com/piotrmurach/tty-table)
* [table\_print](https://github.com/arches/table_print)
* [hirb](https://github.com/cldwalker/hirb)

*DISCLAIMER: My comments regarding these other libraries are based only on my own, possibly flawed
reading of the documentation for, and experimentation with, these libraries at the time of my
writing this. Their APIs, features or documentation may well change between when I write this, and
when you read it. Please consult the libraries&#8217; own documentation for yourself, rather than relying
on these comments.*

While these libraries have their strengths, I have personally found that, for the common use case of
printing a table on the basis of some underlying enumerable collection (such as an ActiveRecord
query result), using these libraries feels more cumbersome than it could be.

For example, suppose we have called `User.all` from the Rails console, and want to print
a table showing the email, first name, last name and ID of each user,
with column headings. Also, we want the ID column to be right-aligned, because it&#8217;s a number.

In **terminal-table**, we could achieve this as follows:

```ruby
rows = User.all.map { |u| [u.email, u.first_name, u.last_name, u.id] }
headings = ["email", "first name", "last name", "id"]
table = Terminal::Table.new(headings: headings, rows: rows)
table.align_column(3, :right)
puts table
```

The problem here is that there is no single source of knowledge about which columns
appear, and in which order. If we want to add another column to the left of &ldquo;email&rdquo;,
we need to amend the rows array, and the headings array, and the index passed to `align_column`.
We bear the burden of keeping these three in sync. This is not be a big deal for small one-off
tables, but for tables that have many columns, or that are constructed
dynamically based on user input or other runtime factors determining the columns
to be included, this can be a hassle and a source of brittleness.

**tty-table** has a somewhat different API to `terminal-table`. It offers both a
&ldquo;row-based&rdquo; and a &ldquo;column-based&rdquo; method of initializing a table. The row-based method
is similar to `terminal-table`&#8217;s in that it burdens the developer with syncing the
column ordering across multiple code locations. The &ldquo;column-based&rdquo; API for `tty-table`, on
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

While this doesn&#8217;t seem too bad, it does mean that the underlying collection (`users`) has to
be traversed multiple times, once for each column, which is inefficient, particularly
if the underlying collection is large. In addition, it&#8217;s not clear how to pass separate
formatting information for each column when initializing in this way. (Perhaps there is a way to do
this, but if there is, it doesn&#8217;t seem to be documented.) So it seems we still have to use
`table.align_column(3, :right)`, which again burdens us with keeping the column index
passed to `align_column` in sync.

As for **table\_print**, this is a handy gem for quickly tabulating ActiveRecord
collections from the Rails console. `table_print` is similar to `tabulo` in that it has a
column-based API, so it doesn&#8217;t suffer from the multiple-source-of-knowledge issue in regards to
column orderings. However, it lacks certain other useful features, such as the ability to repeat
headers every N rows, the automatic alignment of columns based on cell content (numbers right,
strings left), and a quick and easy way to automatically resize columns to accommodate cell content
without overflowing the terminal. Also, as of the time of writing, `table_print`&#8217;s last significant
commit (ignoring a deprecation warning fix in April 2018) was in March 2016.

Finally, it is worth mentioning the **hirb** library. This is similar to `table_print`, in that
it&#8217;s
well suited to quickly displaying ActiveRecord collections from the Rails console. However, like
`table_print`, there are certain useful features it&#8217;s lacking; and using it outside the console
environment seems cumbersome. Moreover, it seems no longer to be maintained. At the time of writing,
its last commit was in March 2015.

<a name="contributing"></a>
## Contributing [&#x2191;](#contents)

Issues and pull requests are welcome on GitHub at https://github.com/matt-harvey/tabulo.

To start working on Tabulo, `git clone` and `cd` into your fork of the repo, then run `bin/setup` to
install dependencies.

`bin/console` will give you an interactive prompt that will allow you to experiment; and
`bundle exec rake spec` will run the test suite. For a list of other Rake tasks that are available in
the development environment, run `bundle exec rake -T`.

<a name="license"></a>
## License [&#x2191;](#contents)

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

[Gem Version]: https://rubygems.org/gems/tabulo
[Documentation]: http://www.rubydoc.info/gems/tabulo
[Build Status]: https://github.com/matt-harvey/tabulo/actions/workflows/tests.yml
[Coverage Status]: https://coveralls.io/github/matt-harvey/tabulo
[Awesome Ruby]: https://github.com/markets/awesome-ruby#cli-utilities

[GV img]: https://img.shields.io/gem/v/tabulo.svg
[DC img]: https://img.shields.io/badge/documentation-v2.8.2-blue.svg
[BS img]: https://github.com/matt-harvey/tabulo/actions/workflows/tests.yml/badge.svg
[CS img]: https://img.shields.io/coveralls/matt-harvey/tabulo.svg
[AR img]: https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg
