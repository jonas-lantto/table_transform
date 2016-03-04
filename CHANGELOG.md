# TableTransform change log

All notable changes to this project will be documented in this file.

TableTransform is still in pre-release state. This means that its APIs and behavior are subject to breaking changes without deprecation notices. Until 1.0, version numbers will follow a [Semver][]-ish `0.y.z` format, where `y` is incremented when new features or breaking changes are introduced, and `z` is incremented for lesser changes or bug fixes.

## [Unreleased]
* Supports formulas in columns
* Helper functions to create formulas

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
[Unreleased]: https://github.com/jonas-lantto/table_transform/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/jonas-lantto/table_transform/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/jonas-lantto/table_transform/compare/v0.1.0...v0.2.0