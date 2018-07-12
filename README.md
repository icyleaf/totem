# totem

[![Language](https://img.shields.io/badge/language-crystal-776791.svg)](https://github.com/crystal-lang/crystal)
[![Tag](https://img.shields.io/github/tag/icyleaf/totem.svg)](https://github.com/icyleaf/totem/blob/master/CHANGELOG.md)
[![Build Status](https://img.shields.io/circleci/project/github/icyleaf/totem/master.svg?style=flat)](https://circleci.com/gh/icyleaf/totem)

Crystal configuration with spirit. Inspired from Go's [viper](https://github.com/spf13/viper).

<!-- TOC -->

- [Why Totem?](#why-totem)
- [Installation](#installation)
- [Usage](#usage)
  - [Operating configuration](#operating-configuration)
  - [Loading configuration](#loading-configuration)
    - [From raw string](#from-raw-string)
    - [From file](#from-file)
  - [Wirting configuration](#wirting-configuration)
- [Contributing](#contributing)
- [Contributors](#contributors)

<!-- /TOC -->

## Why Totem?

Configuration file formats is always the problem, you want to focus on building awesome things. Totem is here to help with that.

Totem has following features:

- Load and parse a configuration file or string in JSON, YAML formats.
- Provide a mechanism to set default values for your different configuration options.
- Provide a mechanism to set override values for options specified through command line flags.
- Provide an alias system to easily rename parameters without breaking existing code.
- Write configuration to file with JSON, YAML formats.

Uses the following precedence order. Each item takes precedence over the item below it:

- alias
- explicit call to `set`
- config
- default

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  totem:
    github: icyleaf/totem
```

## Usage

```crystal
require "totem"
```

### Operating configuration

```crystal
r = Totem.new
r.set_default "name", "foo"
r.get("name").as_s # => "foo"

r.set("name", "bar")
r.register_alias(alias_key: "key", key: "name")
r.get("name").as_s # => "bar"
r.get("key").as_s # => "bar"
```

### Loading configuration

Support `JSON` and `YAML` data from raw stirng and file.

#### From raw string

Load yaml string

```crystal
raw = <<-EOF
Hacker: true
name: steve
hobbies:
- skateboarding
- snowboarding
- go
clothing:
  jacket: leather
  trousers: denim
  pants:
    size: large
age: 35
eyes : brown
EOF

r = Totem.from_yaml raw
r.get("Hacker").as_bool # => true
r.get("age").as_i # => 35
r.get("clothing").as_h["pants"].as_h["size"].as_s.should # => "large"
```

Load json string

```crystal
raw = <<-EOF
{
  "id": "0001",
  "type": "donut",
  "name": "Cake",
  "ppu": 0.55,
  "batters": {
    "batter": [
      {
        "type": "Regular"
      },
      {
        "type": "Chocolate"
      },
      {
        "type": "Blueberry"
      },
      {
        "type": "Devil's Food"
      }
    ]
  }
}
EOF

r = Totem.from_json raw
r.get("Hacker").as_bool # => true
r.get("age").as_i # => 35
r.get("clothing").as_h["pants"].as_h["size"].as_s.should # => "large"
```

#### From file

Load yaml file from file with path

```crystal
r = Totem.from_yaml "./spec/fixtures/config.yaml"
r.get("Hacker").as_bool # => true
r.get("age").as_i # => 35
r.get("clothing").as_h["pants"].as_h["size"].as_s.should # => "large"
```

Load json file from file with multi-paths

```crystal
r = Totem.from_yaml "config.yaml", ["/etc", "."m "./spec/fixtures"]
r.get("Hacker").as_bool # => true
r.get("age").as_i # => 35
r.get("clothing").as_h["pants"].as_h["size"].as_s.should # => "large"
```

### Wirting configuration

```
raw = <<-EOF
Hacker: true
name: steve
hobbies:
- skateboarding
- snowboarding
- go
clothing:
  jacket: leather
  trousers: denim
  pants:
    size: large
age: 35
eyes : brown
EOF

r = Totem.from_yaml raw
r.set("nickname", "Freda")
r.set("eyes", "blue")
r.write("profile.json")
```

## Todo

- [ ] Reading from environment variables
- [ ] Serialize configuration to `Struct`
- [ ] Reading from INI, TOML and etc formatted files.
- [ ] Reading from remote key-value database (redis or memcache)
- [ ] Reading from remote config systems (etcd or Consul)

## Contributing

1. Fork it (<https://github.com/icyleaf/totem/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [icyleaf](https://github.com/icyleaf) icyleaf - creator, maintainer
