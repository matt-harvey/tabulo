# Changelog

### v2.8.2

* Relax dependencies to address incompatibility with recent Rubocop version.
  Thanks to Fabrizio Monti ([@delphaber](https://github.com/delphaber)) for this fix:
  https://github.com/matt-harvey/tabulo/pull/23.
* Add CI coverage for Ruby 3.2
* Upgrade dependency versions in Github action to address deprecation warnings

### v2.8.1

* Upgrade dependency versions
* Minor documentation fixes

### v2.8.0

* Add `except:` param to `Tabulo::Table#pack` method, allowing specific
  columns to be excluded from the action of `.pack`.
  Thanks to Janosch Müller ([@jaynetics](https://github.com/jaynetics)) for this feature:
  https://github.com/matt-harvey/tabulo/pull/21.
* Provide method `Tabulo::Table#autosize_columns`, allowing columns to be auto-sized
  to fit their contents' widths, without having to call `.pack` (which also has
  other effects on the table). This method also has an `except:` param allowing columns
  to be excluded from its action.
* Provide method `Tabulo::Table#shrink_to`, allowing the table's width to be reduced
  so as not to exceed a given target number of characters (or the argument `:screen`
  meaning "width of terminal"), independently of the `.pack` method.
  This method also has an `except:` param allowing columns to be excluded from its action.
* Fix `max_table_width:` param to `.pack` not being respected if table title was
  wider than terminal.
* Documentation improvements
* Fix broken documentation links.
  Thanks to Janosch Müller ([@jaynetics](https://github.com/jaynetics)):
  https://github.com/matt-harvey/tabulo/pull/19.
* Add Ruby 3.1 to CI config

### v2.7.3

* Fix malformed YARD documentation for `Tabulo::Table#initialize` method

### v2.7.2

* Minor documentation improvements and tweaks
* Upgrade Ruby patch versions in CI config

### v2.7.1

* Dependency version upgrades
* Minor documentation improvements and tweaks

### v2.7.0

* Add `wrap_preserve` option, allowing whole words to be preserved when wrapping.
* Internal: Use GitHub actions instead of Travis

### v2.6.3

* Update dependency versions

### v2.6.2

* Ensure line break character sequences are property formatted in output, regardless
  of whether they are "\r\n", "\r" or "\n".

### v2.6.1

* Update dependency versions
* Minor documentation improvements

### v2.6.0

* Add an additional, optional parameter to `styler`, `header_styler` and `title_styler`
  callbacks, which will receive the index (0, 1 or etc.) of the line within the cell
  being styled.
* Allow padding to be configured on a column-by-column basis.
* Minor documentation improvements.

### v2.5.0

* Add option of table title, together with options for styling and aligning the title

### v2.4.1

* Fix warnings under Ruby 2.7
* Fix minor error in README
* Minor documentation tweaks

### v2.4.0

* Add additional, optional `CellData` parameter to `styler` and `formatter` callbacks
* Add optional `column_index` parameter to `header_styler` callback
* Add optional `row_index` parameter to `extractor` callback
* Add `rake yard` Rake task for generating YARD documentation
* Minor documentation fixes
* Upgrade dependency version: `unicode-display_width` gem to 1.7.0

### v2.3.3

* Fix styler option on Table initializer, which had no effect

### v2.3.2

* Update Rake version to address vulnerability CVE-2020-8130

### v2.3.1

* Documentation improvements
* Update dependency versions
* Minor refactoring
* Update Ruby gem description and summary

### v2.3.0

* Provide `#remove_column` method.
* Provide `before` option to `#add_column`, to allow insertion of column into non-final position.
* Provide `styler` and `header_styler` options in table initializer, to enable default stylers
  to be set for all columns.
* Documentation improvements and code tidy-ups.

### v2.2.0

* New `column_formatter` option on `Tabulo::Table` initializer, enabling the table's default column
  formatter to be customized.
* New `row_divider_frequency` option on `Tabulo::Table` initializer, to add a horizontal dividing line
  after every N rows.

### v2.1.1

* Fix issue where blank lines appear in table when certain border types (e.g. `:classic`) are
  used with a non-nil `border_styler`.
* Minor documentation fix

### v2.1.0

* New `reduced_ascii` and `reduced_modern` border options
* Fix `column_width` option not properly inherited from original table by the new table created
  by calling #transpose.

### v2.0.2

* Minor documentation fixes

### v2.0.1

* Minor documentation fix

### v2.0.0

#### New features

* New `border` option for `Tabulo::Table` initializer allows for better customization of border and
  divider characters, using a preset list of options, viz.: `:ascii`, `:modern`, `:markdown`,
  `:blank` and `:classic`. In particular, the `:modern` border option uses smoothly drawn Unicode
  line characters; and the `:markdown` option renders a GitHub-flavoured Markdown table.
* `Tabulo::Table#horizontal_rule` method accepts `:top`, `:bottom` and `:middle` options to allow
  the appropriate border characters to be used depending on its intended position in the table.
* When iterating a `Tabulo::Row`, it's now possible to get the formatted string value of an individual
  `Tabulo::Cell`, not just its underlying "raw" value.
* Column padding can now optionally be configured separately for left and right column sides, by
  passing a 2-element Array to the `column_padding` option of the `Tabulo::Table` initializer.

#### Breaking changes

* A `Tabulo::Row` is now a collection of `Tabulo::Cell`, not a collection of underlying "raw"
  values. This makes it easier to get at both formatted string values and underlying "raw" values of
  `Cell`s when traversing a `Row`. To get at the raw underlying value, call `Tabulo::Cell#value`.
* Remove deprecated `columns` option from `Tabulo::Table` initializer
  (existing `cols` positional parameter now renamed to `columns`).
* Remove deprecated `shrinkwrap!` method (use `pack` instead).
* By default, table now has a border line at the bottom. Pass `:classic` to the `border` option of
  the `Tabulo::Table` initializer to get the old behaviour.
* Removal of `horizontal_rule_character`, `vertical_rule_character` and `intersection` character
  options from `Tabulo::Table` initializer, and from `Tabulo::Table#transpose` method. Use the
  `border` option instead.

#### Other noteworthy changes

* Test coverage is now at exactly 100%
* `hirb` gem now mentioned in README

### v1.5.1

* Dependency version upgrades
* Minor documentation fixes

### v1.5.0

* Support use of ANSI escape sequences to add colours and
  other styling to table elements without breaking the formatting.
* Major refactor, moving various computations into a new Cell class.

### v1.4.1

* Minor documentation fix

### v1.4.0

* New `#transpose` function to produce a new Table in which the rows and
  columns are transposed relative to the original one.
* Properly handle multibyte characters when calculating widths, wrapping etc..

### v1.3.0

* More ergonomic Table initializer, allowing you to specify columns directly as varargs rather
  than as an array passed to `columns:` option (the latter is now deprecated)
* New `#pack` method to autosize table, capping total table width at width of terminal
  by default (replaces `#shrinkwrap!` method, now deprecated)
* Ability to set table-level defaults for column header and body cell alignments
* Accessor methods for `source` attribute, representing the underlying collection
  being tabulated, facilitating reuse of the same table to tabulate different collections
* Documentation improvements

### v1.2.2

* Improve documentation.

### v1.2.1

* Improve documentation in README.
* Update Travis config.
* Change homepage in Gemspec

### v1.2.0

* Allow customization of padding.

### v1.1.0

* Allow customization of horizontal divider, vertical divider and intersection characters.

### v1.0.1

* Fix deprecation warnings.
* Update bundler version development dependency.

### v1.0.0

* Decision to release stable version!
* Minor implementation and documentation tweaks.

### v0.6.3

* Throw an exception if column labels are not unique.

### v0.6.2

* Explicitly support only Ruby >= 2.1.10.

### v0.6.1

* Fix Table#shrinkwrap! handling of newlines within header cell content.
* README now correctly formatted by rubydoc.info.

### v0.6.0

* Correctly handle newlines in cell content.
* Use keyword arguments instead of option hashes.
* Write remaining pending specs.

### v0.5.1

* Unsuccessful attempt to fix broken appearance of http://www.rubydoc.info/gems/tabulo/0.5.1

### v0.5.0

* Add Table#shrinkwrap! method to automate column widths so they "just fit".
* Improve documentation.

### v0.4.2

* Improve README.
* Fix error when printing a Table, or a Row thereof, when the Table doesn't
  have any columns.
* Remove unused development dependency on yard-tomdoc.
* Write more specs.

### v0.4.1

* Update README to reflect default column width of 12.

### v0.4.0

* Increase default column width from 8 to 12
* Allow default column width to be configured when initializing a Table
* Minor code tidy-ups, including removal of undocumented ability for
  Table#add_column to accept a Column instance directly.

### v0.3.1

* Fix width and other options ignored by Table#add_column.

### v0.3.0

* Rename Table#header_row to Table#formatted_header
* Improve documentation, and use Yardoc instead of Tomdoc
* Remove Tabulo::Column from the publicly documented API.

### v0.2.2

* Write documentation

### v0.2.1

* Code tidy-ups
* Tidy-ups and improvements to README, including adding badges for test coverage etc..

### v0.2.0

* Allow columns to be initialized with `columns` option in `Table` initializer
* Removed redundant `truncate` option.
* Rename `wrap_cells_to` to `wrap_body_cells_to`.
* Improve README.

### v0.1.0

Initial release.
