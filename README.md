# shdotenv

dotenv support for shell and POSIX-compliant `.env` syntax specification.

## The goals of this project

1. Provide language-independent CLI utilities
2. Provide a library that can safely load .env file from shell scripts
3. Define POSIX shell compatible .env syntax specification
4. Support for .env syntax dialects for interoperation

## Requirements

`shdotenv` is a single file shell script with embedded awk script.

- POSIX shell (dash, bash, ksh, zsh, etc)
- awk (gawk, nawk, mawk, busybox awk)

## Install

Download `shdotenv` (shell script) from [releases](https://github.com/ko1nksm/shdotenv/releases).

```console
$ wget https://github.com/ko1nksm/shdotenv/releases/download/[TAG]/shdotenv -O $HOME/bin/shdotenv
$ chmod +x $HOME/bin/shdotenv
```

### Build your own

Requires [shfmt](https://github.com/mvdan/sh).

```console
$ git clone https://github.com/ko1nksm/shdotenv.git
$ cd shdotenv
$ make
$ make install PREFIX=$HOME
```

## How to use

### Usage

```
Usage: shdotenv [OPTION]... [--] [COMMAND [ARG]...]

  -d, --dialect DIALECT  Specify the .env dialect [default: posix]
                           (posix, ruby, node, python, php, go, docker)
  -s, --shell SHELL      Output in the specified shell format [default: posix]
                           (posix, fish)
  -e, --env ENV_PATH     Location of the .env file [default: .env]
                           Multiple -e options are allowed
      --overload         Overload predefined environment variables
  -n, --noexport         Do not export keys without export prefix
  -g, --grep PATTERN     Output only those that match the regexp pattern
  -k, --keyonly          Output only variable names
  -q, --quiet            Suppress all output
  -v, --version          Show the version and exit
  -h, --help             Show this message and exit
```

### Use as CLI utility

Set environment variables and execute the specified command.

```sh
shdotenv [OPTION]... <COMMAND> [ARGUMENTS]...
```

### Use as shell script library

Load the .env file into the shell script.

```sh
eval "$(shdotenv [OPTION]...)"
```

When run on the shell, it exports the environment variables to the current shell.

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
- The following characters in double quoted values must be escaped with `\`: <code> $ ` " \ </code>
- No support for backslash escapes except for the above (i.e., `\n` is not a newline)
- Variable expansion is only available if it is double-quoted
- Bracing is required for variable expansion (Only `${VAR}` is supported)

TODO: ~~For detailed specifications, see~~

### Supported dialects

The formal `.env` syntax for this project is `posix` only.
The `posix` is a subset of the POSIX shell and is compatible with shell scripts.
Support for other .env syntax dialects is for interoperability purposes.
Compatibility will be improved gradually, but is not fully compatible.
Reports of problems are welcome.

- docker: [docker](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)
- ruby: [dotenv](https://github.com/bkeepers/dotenv)
- node: [dotenv](https://github.com/motdotla/dotenv) + [dotenv-expand](https://github.com/motdotla/dotenv-expand)
- python: [python-dotenv](https://github.com/theskumar/python-dotenv)
- php: [phpdotenv](https://github.com/vlucas/phpdotenv)
- go: [godotenv](https://github.com/joho/godotenv)
