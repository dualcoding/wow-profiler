# Changelog

## [0.3] 2017-08-20
### Added
- Header showing column names
- Column "mem/ncalls" for memory and times called
- The sorting of entries can be changed by clicking on the header

## [0.2] 2017-08-20
### Changed
- Entries with the same CPU time (usually 0) are sorted in alphabetical order.
- Tables not containing any child functions are no longer shown.
### Fixed
- Should no longer cause taint.
- The sorting of entries is stable, preventing them from jumping around.
- Cycle detection no longer prevents duplicates.

## [0.1] 2017-08-19
- First alpha release.
### Added
- Working but ugly UI.
- Keeps track of functions added to the global namespace by addons.
