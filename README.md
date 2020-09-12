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
csa [options]
    -n, --name NAME                  The Name of the project
    -u, --url URL                    The URL of the template
    -y, --yes                        Use default settings
    -h, --help                       Prints help
```

e.g.

1. `csa`
1. `csa demo`
1. `csa demo -y`
1. `csa demo -u https:...`

## Testing

run `rspec --format doc`
