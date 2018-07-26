# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## TODO

- [ ] Writting to file with dotenv format.
- [ ] Reading from TOML and etc formatted files.
- [ ] Reading from remote key-value database (redis or memcache)
- [ ] Reading from remote config systems (etcd or Consul)

## [0.2.1] (2018-07-26)

### Fixed

- Fix do throw an exception to call `#mapping` with unkown key.

## [0.2.0] (2018-07-25)

### Added

- Fetching all `#keys` and `#flat_keys`.
- Iterating all settings use `#settings` or `#each`.

### Changed

- Use the value of `#settings` to dump json or yaml string (more accurate).
- Use [popcorn](https://github.com/icyleaf/popcorn) to easy and safe casting type.

### Fixed

- Fix cast failed with JSON::Any/YAML::Any with `#as_h?` and `#as_a?`
- Fix typo in README [#1](https://github.com/icyleaf/totem/pull/1) (thanks @[dancrew32](https://github.com/dancrew32))

## [0.1.0] (2018-07-20)

:star2:First beta version:star2:

[Unreleased]: https://github.com/icyleaf/totem/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/icyleaf/totem/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/icyleaf/totem/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/icyleaf/totem/compare/03303bead652c98c51a68c39a44908c7ed2f9327...v0.1.0
