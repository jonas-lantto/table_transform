# TableTransform change log

All notable changes to this project will be documented in this file.

TableTransform is still in pre-release state. This means that its APIs and behavior are subject to breaking changes without deprecation notices. Until 1.0, version numbers will follow a [Semver][]-ish `0.y.z` format, where `y` is incremented when new features or breaking changes are introduced, and `z` is incremented for lesser changes or bug fixes.

## [Unreleased]

* Added format capability for columns when published as Excel 

## [0.2.0][] (2016-02-16)

* Added ability to publish Tables in *Microsoft Excel* format

Fixes:

* Require at least non empty header row to be present in Table

## 0.1.0 (2016-02-10)

* Initial release including Table

[Semver]: http://semver.org
[Unreleased]: https://github.com/jonas-lantto/table_transform/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/jonas-lantto/table_transform/compare/v0.1.0...0.2.0