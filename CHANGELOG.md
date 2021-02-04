# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

> TODO

## [0.6.2] (2021-02-04)

### Fixed

- Compatibility with Crystal 0.36

## [0.6.1] (2020-04-10)

### Fixed

- Compatibility with Crystal 0.34

### Changed

- Use `Log` instead of legacy `Logger` from Crystal 0.34 [#84](https://github.com/icyleaf/totem/pull/84)

## [0.6.0] (2019-11-21)

Long time no see 🙇‍♂️

### Fixed

- Compatibility with Crystal 0.31. #[17](https://github.com/icyleaf/totem/pull/17)
- Fix remote provider `etcd` (ONLY works etcd `v2` API). #[17](https://github.com/icyleaf/totem/pull/17)

## [0.5.2] (2018-12-07)

### Added

- Add environment support. (see [#13](https://github.com/icyleaf/totem/issues/13))
- Add config path position in `Totem::Configbuilder`. (see [#12](https://github.com/icyleaf/totem/issues/12))

### Changed

- Optimize search config performance.
- Formatted sevrity in logger.

### Fixed

- Close IO after read the content.

## [0.5.1] (2018-11-06)

### Fixed

- Compatibility with Crystal 0.27

## [0.5.0] (2018-09-27)

### Changed

- Separate `#fetch` method to two methods with different behavior. (see [#8](https://github.com/icyleaf/totem/issues/8))
- Add new `#register` method instead of `#register_adapter` and `#register_alias` in `Totem::ConfigTypes`, the latters marked **DEPRECATED**.

### Added

- Add config builder to configure easily. (see [#7](https://github.com/icyleaf/totem/pull/7))
- Add `Time` class support in `Totem::Config`.
- Add `#as_f32/as_f32?` methods in `Totem::Any`.

## [0.4.0] (2018-07-31)

### Added

- Add remote provider extensions.
- Add redis/etcd to remote providers.

## [0.3.0] (2018-07-27)

### Added

- Add adapter for configuration formats, writting and using custom adapter. (see [#3](https://github.com/icyleaf/totem/issues/3))
- Add write to file with dotenv format.
- Add Totem::Any equal with other class & struct.
- Add nested key setting for the raw content of configuration formats. (see [specs](https://github.com/icyleaf/totem/blob/master/spec/totem/config_spec.cr#L609))
- Improved inspect output with `#pp` or `#pp!`.

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

[Unreleased]: https://github.com/icyleaf/totem/compare/v0.6.2...HEAD
[0.6.2]: https://github.com/icyleaf/totem/compare/v0.6.1...v0.6.2
[0.6.1]: https://github.com/icyleaf/totem/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/icyleaf/totem/compare/v0.5.2...v0.6.0
[0.5.2]: https://github.com/icyleaf/totem/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/icyleaf/totem/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/icyleaf/totem/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/icyleaf/totem/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/icyleaf/totem/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/icyleaf/totem/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/icyleaf/totem/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/icyleaf/totem/compare/03303bead652c98c51a68c39a44908c7ed2f9327...v0.1.0
