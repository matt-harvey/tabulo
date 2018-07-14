# Changelog

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
