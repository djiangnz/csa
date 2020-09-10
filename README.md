# [Create Swift App](https://rubygems.org/gems/csa)

a command line tool helps you create a swift app from a template

## Installation

install it yourself as:

    $ gem install csa

## Usage

```shell
csa [Project Name] [default template url]
```

or

```shell
csa [options]
    -n, --name NAME                  The Name of the project
    -d, --dir DIR                    The DIR of the template
    -u, --url URL                    The URL of the template
    -h, --help                       Prints help
```

e.g.

1. `csa`
1. `csa demo`
1. `csa demo -u https:...`
1. `csa demo -d /a template dir/`

## Testing

run `rspec --format doc`
