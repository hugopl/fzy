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
