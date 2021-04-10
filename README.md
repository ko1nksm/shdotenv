# shdotenv

dotenv support for shell scripts and POSIX-compliant `.env` specification

## The goals of this project

1. Provide a library that can safely load .env from shell scripts
2. Provide language-independent CLI utilities
3. Define .env syntax for POSIX shell script compatible
4. Support for .env dialects for interoperation

## Requirements

- POSIX shell (dash, bash, ksh, zsh, etc)
- awk (gawk, nawk, mawk, busybox awk)

## Install

```console
make
make install PREFIX=$HOME
```

## How to use

### Usage

```
Usage: shdotenv [OPTION]... [--] [COMMAND [ARG]...]

  -d, --dialect     Specify the .env dialect [default: posix]
  -e, --env         Location of the .env file [default: .env]
                    Multiple -e options are allowed
      --overload    Overload predefined environment variables
  -a, --allexport   Exprot all variables
  -k, --keyonly     Output only variable names
  -q, --quiet       Suppress all output
  -v, --version     Show the version and exit
  -h, --help        Show this message and exit
```

### Use as library

```sh
eval "$(shdotenv [OPTION]...)"
```

### Use as CLI utility

```sh
shdotenv [OPTION]... <COMMAND> [ARGUMENTS]...
```

For normal use cases, the `-a` (`--allexport`) option will be necessary. It is useful to define alias.

```sh
alias shdotenv="shdotenv -a"
alias dotenv="shdotenv -a" # Use as an alternative to dotenv
```

### Additional CLI utility

#### contrib/dockerenv

Support `.env` syntax by `--env-file` option. It supports variable expansion and multi-line environment variables.

Example: (Use `dockerenv` instead of `docker`)

```sh
dockerenv run --env-file .env -it debian
```

## .env file syntax

```sh
# dotenv posix
# This is a comment line, The above is an optional directive
COMMENT=The-#-sign-is-a-character # Spaces is required before the comment

UNQUOTED=value1 # Spaces and these characters are not allowed: {}[]()<>"'`!$&~|;\
SINGLE_QUOTED='value 2' # Single quotes cannot be used as value
DOUBLE_QUOTED="value 3" # Only these characters need to be \ escaped: $`"\

MULTILINE="line1
line2: \n is not a newline
line3"
LONGLINE="https://github.com/ko1nksm\
/shdotenv/blob/main/README.md"

ENDPOINT="http://${HOST}/api"

export EXPORT1="value"
export EXPORT2 # Equivalent to: export EXPORT2="${EXPORT2:-}"
```

- The first line is an optional directive which, if omitted, defaults to `posix`
- Spaces before and after `=` are not allowed
- Quoting is not required, but spaces and some symbols are not allowed
- Single-quoted values cannot contains single quote in it
- The following characters in double quoted values must be escaped with `\`: $`"\
- No support for backslash escapes except for the above (i.e., `\n` is not a newline)
- Variable expansion is only available if it is double-quoted
- Bracing is required for variable expansion (Only `${VAR}` is supported)

TODO: ~~For detailed specifications, see~~

### Supported dialects

The formal `.env` syntax for this project is `posix` only.
The `posix` is a subset of the POSIX shell and is compatible with shell scripts.
Support for other .env dialects is for interoperability purposes and is not fully compatible.

- docker: [docker](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)
- ruby: [dotenv](https://github.com/bkeepers/dotenv)
- node: [dotenv](https://github.com/motdotla/dotenv) + [dotenv-expand](https://github.com/motdotla/dotenv-expand)
- python: [python-dotenv](https://github.com/theskumar/python-dotenv)
- php: [phpdotenv](https://github.com/vlucas/phpdotenv)
- go: [godotenv](https://github.com/joho/godotenv)
