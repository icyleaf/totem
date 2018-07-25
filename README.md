![totem-logo](https://github.com/icyleaf/totem/raw/master/logo-small.png)

# Totem

[![Language](https://img.shields.io/badge/language-crystal-776791.svg)](https://github.com/crystal-lang/crystal)
[![Tag](https://img.shields.io/github/tag/icyleaf/totem.svg)](https://github.com/icyleaf/totem/blob/master/CHANGELOG.md)
[![Build Status](https://img.shields.io/circleci/project/github/icyleaf/totem/master.svg?style=flat)](https://circleci.com/gh/icyleaf/totem)

Crystal configuration with spirit. Inspired from Go's [viper](https://github.com/spf13/viper). Totem Icon by lastspark from <a href="https://thenounproject.com">Noun Project</a>.

<!-- TOC -->

- [What is Totem?](#what-is-totem)
- [Installation](#installation)
- [Quick Start](#quick-start)
  - [Operating configuration](#operating-configuration)
  - [Loading configuration](#loading-configuration)
    - [From raw string](#from-raw-string)
    - [From file](#from-file)
- [Usage](#usage)
  - [Load configuration with multiple paths](#load-configuration-with-multiple-paths)
  - [Set Alias and using alias](#set-alias-and-using-alias)
  - [Working with nested key](#working-with-nested-key)
  - [Working with Envoriment variables](#working-with-envoriment-variables)
  - [Serialization](#serialization)
  - [Storing configuration to file](#storing-configuration-to-file)
- [Contributing](#contributing)
- [Contributors](#contributors)

<!-- /TOC -->

## What is Totem?

Configuration file formats is always the problem, you want to focus on building awesome things. Totem is here to help with that.

Totem has following features:

- Load and parse a configuration file or string in JSON, YAML, dotenv formats.
- Reading from environment variables.
- Provide a mechanism to set default values for your different configuration options.
- Provide an alias system to easily rename parameters without breaking existing code.
- Write configuration to file with JSON, YAML formats.

Uses the following precedence order. Each item takes precedence over the item below it:

- alias
- override, explicit call to `set`
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

## Quick Start

```crystal
require "totem"
```

### Operating configuration

```crystal
totem = Totem.new
totem.set_default("name", "foo")
totem.set_defaults({
  "age"    => 18,
  "gender" => "male",
  "hobbies" => [
    "skateboarding",
    "snowboarding",
    "go"
  ]
})

totem.get("name").as_s # => "foo"
totem.get("age").as_i # => 18
totem.set("name", "bar")
totem.alias(alias_key: "key", key: "name")
totem.get("name").as_s # => "bar"
totem.get("key").as_s # => "bar"
```

### Loading configuration

Support `JSON`, `YAML` and dotenv data from raw string and file.

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

totem = Totem.from_yaml raw
totem.get("Hacker").as_bool                           # => true
totem.get("age").as_i                                 # => 35
totem.get("clothing").as_h["pants"].as_h["size"].as_s # => "large"
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

totem = Totem.from_json raw
totem.get("name")                                         # => "Cake"
totem.get("ppu")                                          # => 0.55
totem.get("batters").as_h["batter"].as_a[0].as_h["type"]  # => "Regular"
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

totem = Totem.from_env raw
totem.get("str")                    # => "foo"
totem.get("str_with_comments")      # => bar
totem.get("str_with_hash_symbol")   # => "abc#123"
totem.get("int")                    # => "33"
```

#### From file

```crystal
# Load yaml file from file with path
totem = Totem.from_file "./spec/fixtures/config.yaml"

# Load json file from file with multi-paths
totem = Totem.from_file "config.yaml", ["/etc", ".", "./spec/fixtures"]

# Load dotenv file
totem = Totem.from_file "sample.env"
```

## Usage

### Load configuration with multiple paths

Totem can search multiple paths, but currently a single Totem instance only supports a single
configuration file.

```crystal
totem = Totem.new("config", "/etc/totem/")  # => New a instance with name and path of config file
totem.config_paths << "~/.totem"            # => path to look for the config file in
totem.config_paths << "./config"            # => optionally look for config in the working directory
begin
  totem.load!                               # => Find and read the config file (order by yaml/yml/json/env)
rescue e
  puts "Fatal error config file: #{e.message}"
end
```

### Set Alias and using alias

Aliases permit a single value to be referenced by multiple keys

```crystal
totem.alias("nickname", "Name")

totem.set("name", "foo")
totem.set("nickname", "bar")

totem.get("name")       # => "foo"
totem.get("nickname")   # => "foo"
```

### Working with nested key

All accessor methods accept nested key:

```crystal
totem.set_default("profile.user.name", "foo")
totem.set("profile.user.age", 13)
totem.alias("username", "profile.user.name")
totem.get("profile.user.age")
```

### Working with Envoriment variables

Totem has full support for environment variables, example:

```crystal
ENV["ID"] = "123"
ENV["FOOD"] = "Pinapple"
ENV["NAME"] = "Polly"

totem = Totem.new

totem.bind_env("ID")
totem.get("id").as_i        # => 123

totem.bind_env("f", "FOOD")
totem.get("f").as_s         # => "Pinapple"

totem.automative_env
totem.get("name").as_s      # => "Polly"
```

Working with envoriment prefix:

```crystal
totem.automative_env(prefix: "totem")
# Same as
# totem.env_prefix = "totem"
# totem.automative_env = true

totem.get("id").as_i    # => 123
totem.get("food").as_s  # => "Pinapple"
totem.get("name").as_s  # => "Polly"
```

### Serialization

Serialize configuration to `Struct`, at current stage you can pass a `JSON::Serializable`/`YAML::Serializable` struct to mapping.

```crystal
struct Profile
  include JSON::Serializable

  property name : String
  property hobbies : Array(String)
  property age : Int32
  property eyes : String
end

totem = Totem.from_file "spec/fixtures/config.yaml"
profile = totem.mapping(Profile)
profile.name      # => "steve"
profile.age       # => 35
profile.eyes      # => "brown"
profile.hobbies   # => ["skateboarding", "snowboarding", "go"]
```

Serialize configuration with part of key:

```crystal
struct Clothes
  include JSON::Serializable

  property jacket : String
  property trousers : String
  property pants : Hash(String, String)
end

totem = Totem.from_file "spec/fixtures/config.yaml"
clothes = profile.mapping(Clothes, "clothing")
# => Clothes(@jacket="leather", @pants={"size" => "large"}, @trousers="denim")
```

### Storing configuration to file

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

totem = Totem.from_yaml raw
totem.set("nickname", "Freda")
totem.set("eyes", "blue")
totem.store!("profile.json")
```

## Contributing

1. Fork it (<https://github.com/icyleaf/totem/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [icyleaf](https://github.com/icyleaf) icyleaf - creator, maintainer
