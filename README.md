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
  - [Iterating configuration](#iterating-configuration)
  - [Serialization](#serialization)
  - [Storing configuration to file](#storing-configuration-to-file)
- [Q & A](#q--a)
  - [How to debug?](#how-to-debug)
- [Help and Discussion](#help-and-discussion)
- [Donate](#donate)
- [How to Contribute](#how-to-contribute)
- [You may also like](#you-may-also-like)
- [License](#license)

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
totem.bind_env("profile.user.nickname", "PROFILE_USER_NICKNAME")
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

### Iterating configuration

Iterate in Totem is very easy, you can get `#keys`, `#flat_keys`, `#settings` (a.k.a `#to_h`) even iterating it directly with `#each`:

```crystal
totem.settings    # => {"id" => 123, "user" => {"name" => "foobar", "age" => 20}}
totem.keys        # => ["id", "user"]
totem.flat_keys   # => ["id", "user.name", "user.age"]

totem.each do |key, value|
  # do something
end
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

Simple to use `#store!` method.

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

## Q & A

### How to debug?

You can use Crystal built-in `#pp!` method to prints a series of instance variables:

```crystal
pp! totem # => #<Totem::Config:0x107df6f80
 @aliases={"user" => "name"},
 @automatic_env=false,
 @config={},
 @config_delimiter=".",
 @config_file=nil,
 @config_name="config",
 @config_paths=[],
 @config_type="json",
 @defaults={"name" => "Name"},
 @env={},
 @env_prefix=nil,
 @logger=
  #<Logger:0x107deeac0
   @closed=false,
   @formatter=
    #<Proc(Logger::Severity, Time, String, String, IO, Nil):0x1079ab4a0>,
   @io=#<IO::FileDescriptor: fd=1>,
   @level=ERROR,
   @mutex=#<Mutex:0x107df0ed0 @lock_count=0, @mutex_fiber=nil, @queue=nil>,
   @progname="">,
 @logging=false,
 @overrides={"name" => "foo"}>
```

## Help and Discussion

You can browse the API documents:

https://icyleaf.github.io/totem/

You can browse the Changelog:

https://github.com/icyleaf/totem/blob/master/CHANGELOG.md

If you have found a bug, please create a issue here:

https://github.com/icyleaf/totem/issues/new

## Donate

Totem is a open source, collaboratively funded project. If you run a business and are using Totem in a revenue-generating product,
it would make business sense to sponsor Totem development. Individual users are also welcome to make a one time donation
if Totem has helped you in your work or personal projects.

You can donate via [Paypal](https://www.paypal.me/icyleaf/5).

## How to Contribute

Your contributions are always welcome! Please submit a pull request or create an issue to add a new question, bug or feature to the list.

All [Contributors](https://github.com/icyleaf/totem/graphs/contributors) are on the wall.

## You may also like

- [halite](https://github.com/icyleaf/halite) - HTTP Requests Client with a chainable REST API, built-in sessions and loggers.
- [markd](https://github.com/icyleaf/markd) - Yet another markdown parser built for speed, Compliant to CommonMark specification.
- [poncho](https://github.com/icyleaf/poncho) - A .env parser/loader improved for performance.
- [popcorn](https://github.com/icyleaf/popcorn) - Easy and Safe casting from one type to another.
- [fast-crystal](https://github.com/icyleaf/fast-crystal) - 💨 Writing Fast Crystal 😍 -- Collect Common Crystal idioms.

## License

[MIT License](https://github.com/icyleaf/totem/blob/master/LICENSE) © icyleaf