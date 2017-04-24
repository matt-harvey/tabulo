# TODO

* Finish Tomdoc documentation. Link to it at rubydocs from the README. In particular,
  make it clear which methods are part of the public API and which are internal.
* Allow the option of a horizontal rule between each row?
* Consider incorporating a linter / static analysis tool into the build.
* Raise an ArgumentError for disallowed arguments and options (this is
  a library!)
* Document :formatter option in README.
* Allow default column width to be configured at level of Table.
* Rename Table#header_row to Table#header to avoid confusion as it does not
  return a Row.
* Column#initialize should have the same signature as Table#add_column.
