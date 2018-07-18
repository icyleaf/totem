# Totem

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
    - [From Envoriment variables](#from-envoriment-variables)
    - [From file](#from-file)
  - [Wirting configuration](#wirting-configuration)
  - [Serialization](#serialization)
- [Advanced Usage](#advanced-usage)
- [Todo](#todo)
- [Contributing](#contributing)
- [Contributors](#contributors)

<!-- /TOC -->

## Why Totem?

Configuration file formats is always the problem, you want to focus on building awesome things. Totem is here to help with that.

Totem has following features:

- Load and parse a configuration file or string in JSON, YAML, DotEnv formats.
- Provide a mechanism to set default values for your different configuration options.
- Provide a mechanism to set override values for options specified through command line flags.
- Provide an alias system to easily rename parameters without breaking existing code.
- Write configuration to file with JSON, YAML formats.

Uses the following precedence order. Each item takes precedence over the item below it:

- alias
- explicit call to `set`
- env
- config
- default

Totem configuration keys are case insensitive.

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
r.set_default("name", "foo")
r.set_defaults({
  "age"    => 18,
  "gender" => "male",
  "hobbies" => [
    "skateboarding",
    "snowboarding",
    "go"
  ]
})
r.get("name").as_s # => "foo"
r.get("age").as_i # => 18

r.set("name", "bar")
r.alias(alias_key: "key", key: "name")
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
r.get("Hacker").as_bool                           # => true
r.get("age").as_i                                 # => 35
r.get("clothing").as_h["pants"].as_h["size"].as_s # => "large"
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
r.get("name")                                         # => "Cake"
r.get("ppu")                                          # => 0.55
r.get("batters").as_h["batter"].as_a[0].as_h["type"]  # => "Regular"
```

Load dotenv string

```crystal
raw = <<-EOF
# COMMENTS=work
STR='foo'
STR_WITH_COMMENTS=bar         # str with comment
STR_WITH_HASH_SYMBOL="abc#123"#stick comment
INT=33
EOF

r = Totem.from_env raw
r.get("str")                    # => "foo"
r.get("str_with_comments")      # => bar
r.get("str_with_hash_symbol")   # => "abc#123"
r.get("int")                    # => "33"
```

#### From file

Load yaml file from file with path

```crystal
r = Totem.from_file "./spec/fixtures/config.yaml"
r.get("Hacker").as_bool                           # => true
r.get("age").as_i                                 # => 35
r.get("clothing").as_h["pants"].as_h["size"].as_s # => "large"
```

Load json file from file with multi-paths

```crystal
r = Totem.from_file "config.yaml", ["/etc", ".", "./spec/fixtures"]
r.get("name")                                         # => "Cake"
r.get("ppu")                                          # => 0.55
r.get("batters").as_h["batter"].as_a[0].as_h["type"]  # => "Regular"
```

Load dotenv file

```crystal
r = Totem.from_file "sample.env"
r.get("int")                                          # => "42"
r.get("str")                                          # => "foo"
```

### Wirting configuration

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
r.set("nickname", "Freda")
r.set("eyes", "blue")
r.write("profile.json")
```

#### Working with Envoriment variables

Totem has full support for environment variables, example:

```crystal
ENV["ID"] = "123"
ENV["FOOD"] = "Pinapple"
ENV["NAME"] = "Polly"

r = Totem.new

r.bind_env("id")
r.get("id").as_i # => 123

r.bind_env("f", "food")
r.get("f").as_s # => "Pinapple"

r.automative_env
r.get("name") # => "Polly"
```

Working with envoriment prefix:

```crystal
r.automative_env(prefix: "totem")
# Same as
# r.env_prefix = "totem"
# r.automative_env = true

r.get("id").as_i # => 123
r.get("food").as_s # => "Pinapple"
r.get("name") # => "Polly"
```

### Serialization

Serialize configuration to `Struct`, at current stage you can pass a `JSON::Serializable` struct to mapping.

```crystal
struct Profile
  include JSON::Serializable

  property name : String
  property hobbies : Array(String)
  property age : Int32
  property eyes : String
end

r = Totem.from_file "spec/fixtures/config.yaml"
p = r.mapping(Profile)
p.name      # => "steve"
p.age       # => 35
p.eyes      # => "brown"
p.hobbies   # => ["skateboarding", "snowboarding", "go"]
```

Serialize configuration with part of key:

```crystal
struct Clothes
  include JSON::Serializable

  property jacket : String
  property trousers : String
  property pants : Hash(String, String)
end

r = Totem.from_file "spec/fixtures/config.yaml"
c = r.mapping(Clothes, "clothing")
# => Clothes(@jacket="leather", @pants={"size" => "large"}, @trousers="denim")
```

## Advanced Usage




## Todo

- [x] Reading from environment variables
- [x] Serialize configuration to `Struct`
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
