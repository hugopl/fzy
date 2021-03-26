## [0.5.2] - 2021-03-26
### Changed
 - Adjusted the mess I did with shards.yml on 0.5.1 release.

## [0.5.1] - 2021-03-23
### Changed
 - Adjusted shards.yml for Crystal 1.0.0.

## [0.5.0] - 2020-08-03
### Added
 - Added Add `empty?` and `any?` to PreparedHaystack.

## [0.4.0] - 2020-05-17
### Added
 - Added match.index, to return the index of the match on haystack.

## [0.3.0] - 2020-04-10
### Fixed
- Fix build with Crystal 0.34.0.

## [0.2.2] - 2020-03-02
### Fixed
- Fix match positions calculation for long strings.

## [0.2.1] - 2020-02-13
### Fixed
- Fix Fzy.search not returning sorted results.

## [0.2.0] - 2020-02-12
### Added
- Speed improved speed by ~50%.

### Breaking change
- Removed some primitives from API, API now is just:
  - Fzy.search
  - Match class
  - PreparedHaystack class

## [0.1.1] - 2020-01-24
### Added
- Improved speed by 5% by sharing computation between search and postion methods.

## [0.1.0] - 2020-01-24
### Added
- Initial Release
