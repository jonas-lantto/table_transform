# TableTransform change log

All notable changes to this project will be documented in this file.

TableTransform is still in pre-release state. This means that its APIs and behavior are subject to breaking changes without deprecation notices. Until 1.0, version numbers will follow a [Semver][]-ish `0.y.z` format, where `y` is incremented when new features or breaking changes are introduced, and `z` is incremented for lesser changes or bug fixes.

## [Unreleased]

## [0.6.2][] (2016-06-11)
* [FIX] Table filter will include column properties
* Improved documentation

## [0.6.1][] (2016-06-08)
* Added write_xlsx as runtime dependency
* [FIX] Table filter will include formulas

## [0.6.0][] (2016-03-20)
* Added rename table column
* Harmonization of how to work with properties, Table and Column
* Deprecated old metadata functions (to be removed)
    
## [0.5.0][] (2016-03-13)
* Table properties added

## [0.4.0][] (2016-03-05)
* Supports formulas in columns
* Helper functions to create formulas
* Column width estimates format size in calculation 

## [0.3.0][] (2016-02-29)
* Added format capability for columns when published as Excel
* CodeClimate and test coverage added
* Ruby >= 2.1 verified with TravisCI
* Improved documentation

## [0.2.0][] (2016-02-16)
* Added ability to publish Tables in *Microsoft Excel* format
* [FIX] Require at least non empty header row to be present in Table

## 0.1.0 (2016-02-10)
* Initial release including Table

[Semver]: http://semver.org
[Unreleased]: https://github.com/jonas-lantto/table_transform/compare/v0.6.2...HEAD
[0.6.2]: https://github.com/jonas-lantto/table_transform/compare/v0.6.1...v0.6.2
[0.6.1]: https://github.com/jonas-lantto/table_transform/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/jonas-lantto/table_transform/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/jonas-lantto/table_transform/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/jonas-lantto/table_transform/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/jonas-lantto/table_transform/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/jonas-lantto/table_transform/compare/v0.1.0...v0.2.0