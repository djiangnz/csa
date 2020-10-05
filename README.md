# [Create Swift App](https://rubygems.org/gems/csa)

a command line tool helps you create a swift app from a template

## Installation

install it yourself as:

    $ gem install csa

## Usage

```shell
csa [Project Name] [default template URL]
```

or

```shell
Usage: csa [options]
    -n, --name NAME                  The Name of the project
    -u, --url URL                    The URL of the template
    -h, --help                       Prints help
    -y, --yes                        Use default settings
    -v, --version                    Prints Version
```

e.g.

1. `csa`
1. `csa MyApp`
1. `csa MyApp -y`
1. `csa MyApp -u https:...`

## Testing

run `rspec --format doc`
