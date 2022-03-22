![totem-logo](https://github.com/icyleaf/totem/raw/master/logo-small.png)

# Totem

[![Language](https://img.shields.io/badge/language-crystal-776791.svg)](https://github.com/crystal-lang/crystal)
[![Tag](https://img.shields.io/github/tag/icyleaf/totem.svg)](https://github.com/icyleaf/totem/blob/master/CHANGELOG.md)
[![Build Status](https://img.shields.io/circleci/project/github/icyleaf/totem/master.svg?style=flat)](https://circleci.com/gh/icyleaf/totem)

Crystal configuration with spirit. Inspired from Go's [viper](https://github.com/spf13/viper). Totem Icon by lastspark from [Noun Project](https://thenounproject.com).

Configuration file formats is always the problem, you want to focus on building awesome things. Totem is here to help with that.

Totem has following features:

- Reading from JSON, YAML, dotenv formats config files or raw string.
- Reading from environment variables.
- Reading from remote key-value store systems(redis/etcd).
- Provide a mechanism to set default values for your different configuration options.
- Provide an alias system to easily rename parameters without breaking existing code.
- Write configuration to file with JSON, YAML formats.
- Convert config to struct with builder.

And we keep it minimize and require what you want with adapter and remote provider! **No more dependenices what you do not need**.
Only JSON and YAML adapters were auto requires.

Uses the following precedence order. Each item takes precedence over the item below it:

- alias
- override, explicit call to `set`
- env
- config
- kvstores
- default

Totem configuration keys are case insensitive.

<!-- TOC -->

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
  - [Working with environment variables](#working-with-environment-variables)
  - [Working with remote providers](#working-with-remote-providers)
    - [Use redis](#use-redis)
    - [Use etcd](#use-etcd)
  - [Iterating configuration](#iterating-configuration)
  - [Serialization](#serialization)
  - [Storing configuration to file](#storing-configuration-to-file)
- [Advanced Usage](#advanced-usage)
  - [Use config builder](#use-config-builder)
  - [Write a config adapter](#write-a-config-adapter)
  - [Write a remote provider](#write-a-remote-provider)
- [Q & A](#q--a)
  - [How to debug?](#how-to-debug)
- [Help and Discussion](#help-and-discussion)
- [Donate](#donate)
- [How to Contribute](#how-to-contribute)
- [You may also like](#you-may-also-like)
- [License](#license)

<!-- /TOC -->

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

> Add [poncho](https://github.com/icyleaf/poncho) to `shards.yml` and require the adapter.

```crystal
require "totem"
require "totem/config_types/env"    # Make sure you require

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

> Add [poncho](https://github.com/icyleaf/poncho) to `shards.yml` and require the adapter if you need load dotenv file.

```crystal
# Load yaml file from file with path
totem = Totem.from_file "./spec/fixtures/config.yaml"

# Load json file from file with multi-paths
totem = Totem.from_file "config.yaml", ["/etc", ".", "./spec/fixtures"]

# Load dotenv file
totem = Totem.from_file "config.env"
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

### Working with environment variables

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

Working with environment prefix:

```crystal
totem.automative_env(prefix: "totem")
# Same as
# totem.env_prefix = "totem"
# totem.automative_env = true

totem.get("id").as_i    # => 123
totem.get("food").as_s  # => "Pinapple"
totem.get("name").as_s  # => "Polly"
```

### Working with remote providers

Totem retrieve configuration from Key-Value store, which means that you can get your configuration values on the air.
Avaliable providers is `redis` and `etcd`.

#### Use redis

It dependency [crystal-redis](https://github.com/stefanwille/crystal-redis) shard. Install it before use.

```crystal
require "totem"
require "totem/remote_providers/redis"

totem = Totem.new
totem.add_remote(provider: "redis", endpoint: "redis://localhost:6379/0")

totem.get("user:name")      # => "foo"
totem.get("user:id").as_i   # => 123
```

You can also get raw data from one key with `path`:

```crystal
totem.config_type = "json"  # There is no file extension in a stream data, supported extensions are all registed config types in Totem.
totem.add_remote(provider: "redis", endpoint: "redis://localhost:6379/0", path: "config:development")

totem.get("user:name")      # => "foo"
totem.get("user:id").as_i   # => 123
```

#### Use etcd

It dependency [etcd-crystal](https://github.com/icyleaf/etcd-crystal) shard and ONLY works etcd `v2` API. Install it before use.

```crystal
require "totem"
require "totem/remote_providers/etcd"

totem = Totem.new
totem.add_remote(provider: "etcd", endpoint: "http://localhost:2379")

totem.get("user:name")      # => "foo"
totem.get("user:id").as_i   # => 123
```

You can also get raw data from one key with `path`:

```crystal
totem.config_type = "yaml"  # There is no file extension in a stream data, supported extensions are all registed config types in Totem.
totem.add_remote(provider: "etcd", endpoint: "http://localhost:2379", path: "/config/development.yaml")

totem.get("user:name")      # => "foo"
totem.get("user:id").as_i   # => 123
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

## Advanced Usage

### Use config builder

You can generate a configuration with Totem builder with any **Object**.

```crystal
struct Configuration
  include Totem::ConfigBuilder

  build do
    config_type "json"
    config_paths ["/etc/totem", "~/.config/totem", "config/"]
  end
end

config = Configuration.configure do |c|
  c.set_default "name", "foobar"
end

config["name"] # => "foobar"
```

The builder also could mapping config to struct.

```crystal
struct Profile
  include Totem::ConfigBuilder

  property name : String
  property hobbies : Array(String)
  property age : Int32
  property eyes : String

  build do
    config_type "yaml"
    config_paths ["/etc/totem", "~/.config/totem", "config/"]
  end
end

profile = Profile.configure
profile.name          # => "steve"
profile["nested.key"] # => "foo"
```

### Write a config adapter

Creating the custom adapter by integration `Totem::ConfigTypes::Adapter` abstract class. Here has two methods must be implement:
`read` and `write`. For example, let us write a INI adapter:

```crystal
require "ini"

class INIAdapter < Totem::ConfigTypes::Adapter
  def read(raw)
    INI.parse(raw)
  end

  def write(io, config)
    config.settings.each do |key, items|
      next unless data = items.as_h?
      io << "[" << key << "]\n"
      data.each do |name, value|
        io << name << " = " << value << "\n"
      end
    end
  end
end

# Do not forget register it
Totem::ConfigTypes.register_adapter("ini", INIAdapter.new)
# Also you can set aliases
Totem::ConfigTypes.register_alias("cnf", "ini")
```

More examples to review [built-in adapters](https://github.com/icyleaf/totem/blob/master/src/totem/config_types).

### Write a remote provider

Creating the custom remote provider by integration `Totem::RemoteProviders::Adapter` abstract class. Here has two methods must be implement:
`read` and `get`, please reivew the [built-in remote providers](https://github.com/icyleaf/totem/blob/master/src/totem/remote_providers).

## Q & A

### How to debug?

You can use Crystal built-in `#pp` or `#pp!` method to prints a series of instance variables:

```
#<Totem::Config
 @config_paths=["/etc/totem", "~/.totem"],
 @config_name="config",
 @config_type="json",
 @key_delimiter=".",
 @automatic_env=false,
 @env_prefix=nil,
 @aliases={"user" => "profile.user.name"},
 @overrides={"profile" => {"user" => {"gender" => "male"}}, "name" => "foo"},
 @config={"profile" => {"user" => {"gender" => "unkown"}}, "name" => "bar"}},
 @env={"name" => "TOTEM_NAME"},
 @defaults={"name" => "alana"}>
```

## Help and Discussion

You can browse the API documents:

https://icyleaf.github.io/totem/

You can browse the Changelog:

https://github.com/icyleaf/totem/blob/master/CHANGELOG.md

If you have found a bug, please create a issue here:

https://github.com/icyleaf/totem/issues/new

## How to Contribute

Your contributions are always welcome! Please submit a pull request or create an issue to add a new question, bug or feature to the list.

All [Contributors](https://github.com/icyleaf/totem/graphs/contributors) are on the wall.

## You may also like

- [halite](https://github.com/icyleaf/halite) - HTTP Requests Client with a chainable REST API, built-in sessions and middlewares.
- [markd](https://github.com/icyleaf/markd) - Yet another markdown parser built for speed, Compliant to CommonMark specification.
- [poncho](https://github.com/icyleaf/poncho) - A .env parser/loader improved for performance.
- [popcorn](https://github.com/icyleaf/popcorn) - Easy and Safe casting from one type to another.
- [fast-crystal](https://github.com/icyleaf/fast-crystal) - 💨 Writing Fast Crystal 😍 -- Collect Common Crystal idioms.

## License

[MIT License](https://github.com/icyleaf/totem/blob/master/LICENSE) © icyleaf
