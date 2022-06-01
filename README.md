# shdotenv

dotenv for shells with support for POSIX-compliant and multiple .env file syntax

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/ko1nksm/shdotenv/macOS?logo=github)

**Project Status**: Almost complete. Major features have been implemented and v1.0.0 will be released in the near future.

Quoting [bkeepers/dotenv][dotenv]:

> Storing [configuration in the environment](http://12factor.net/config) is one of the tenets of a [twelve-factor app](http://12factor.net). Anything that is likely to change between deployment environments–such as resource handles for databases or credentials for external services–should be extracted from the code into environment variables.

[dotenv]: https://github.com/bkeepers/dotenv

## Why not use `source` or `export`?

It is not safe. There is no formal specification for the .env file syntax, and different languages, libraries, and tools use different syntaxes. If you load a .env file syntax that is incompatible with the POSIX shell syntax, you will get unexpected results and may even result in the execution of scripts.

shdotenv safely loads the syntax of .env files that are compatible with POSIX shell syntax. There is no possibility that the script will be executed. And also, for interoperability, .env files with other syntaxes are supported whenever possible.

## The goals of this project

1. Provide language-independent CLI utilities
2. Provide a library that can safely load .env file from shell scripts
3. Define POSIX shell compatible .env file syntax specification
4. Support for .env file syntax dialects for interoperation

## Requirements

`shdotenv` is a single file shell script with embedded awk script. It uses only the following commands which can be found anywhere.

- POSIX shell (dash, bash, ksh, zsh, etc)
- awk (gawk, nawk, mawk, busybox awk)
- `env` command

## Install

Download `shdotenv` (shell script) from [releases](https://github.com/ko1nksm/shdotenv/releases).

```console
$ wget https://github.com/ko1nksm/shdotenv/releases/latest/download/shdotenv -O $HOME/bin/shdotenv
$ chmod +x $HOME/bin/shdotenv
```

### Build your own

**Build and install only**

```console
$ git clone https://github.com/ko1nksm/shdotenv.git
$ cd shdotenv
$ make build
$ make install PREFIX=$HOME
```

**Full build**

A full build requires requires [shfmt](https://github.com/mvdan/sh), [shellcheck](https://github.com/koalaman/shellcheck) and [shellspec](https://github.com/shellspec/shellspec).

```console
$ git clone https://github.com/ko1nksm/shdotenv.git
$ cd shdotenv
$ make MINIFY=true
$ make install PREFIX=$HOME
```

**Note for developers**: `shdotenv` can be run in source code without building. Please run `src/shdotenv`.

## Usage

```
Usage: shdotenv [OPTION]... [--] [[COMMAND | export] [ARG]...]

  If the COMMAND is specified, it will load .env files and run the command.
  If the COMMAND is omitted, it will output the result of interpreting .env
  files. It can be safely loaded into the shell (For example, using eval).

Options:
  -d, --dialect DIALECT     Specify the .env dialect [default: posix]
                                posix, ruby, node, python,
                                php, go, rust, docker
  -f, --format FORMAT       Output in the specified format [default: sh]
                                sh, csh, fish, json, jsonl, name
  -e, --env ENV_PATH        Location of the .env file [default: .env]
                              Multiple -e options are allowed
                              If the ENV_PATH is "-", read from stdin
  -i, --ignore-environment  Ignore the current environment variables
      --overload            Overload predefined environment variables
      --noexport            Do not append "export" prefix
      --grep PATTERN        Output only names that match the regexp pattern
      --name-only           [Deprecated] Use --format name
                            Output only environment variable names
  -q, --quiet               Suppress all output (useful for test .env files)
  -v, --version             Show the version and exit
  -h, --help                Show this message and exit

Usage: shdotenv export [-n | -p] [--] [NAME]...
  Exports environment variables in posix-compliant .env format.

  -n  List only environment variable names
  -p  Append "export" prefix to environment variable names

  This will be output after the .env files is loaded. If you do not want
  to load it, specify "-e /dev/null". This is similar to "export", "env"
  and "printenv" commands, but quoting correctly and exports only portable
  environment variable name that are valid as identifier for posix shell.
```

## How to use

### Use as a CLI utility

Set environment variables and execute the specified command.

```sh
shdotenv [OPTION]... <COMMAND> [ARGUMENTS]...
```

### Use as a library

Load the .env file into the shell script. When run on the shell, it exports to the current shell.

### sh, bash, ksh, zsh, etc. (POSIX-compliant shells)

```sh
eval "$(shdotenv [OPTION]...)"
```

### csh, tcsh

```tcsh
set newline='\
'
eval "`shdotenv -f csh [OPTION]...`"
```

### fish

```fish
eval (shdotenv -f fish [OPTION]...)
```

### Test the .env file syntax

```sh
shdotenv --quiet --env .env
```

### Export environment variables safely

This is similar to `export`, `env` and `printenv` commands, but quoting correctly and exports only portable environment variable name that are valid as identifier for POSIX shell.

```text
shdotenv export [-n | -p] [NAME]...
```

### Additional CLI utility

#### contrib/dockerenv

The `docker` command has the `--env-file` option, but it only supports setting simple values.

- [docker cannot pass newlines from variables in --env-file files](https://github.com/moby/moby/issues/12997)

This tool makes the files read by `--env-file` compatible with the `.env` format, and supports variable expansion and newlines.

Example: (Use `dockerenv` instead of `docker`)

```sh
dockerenv run --env-file .env -it debian
```

## .env file syntax

```sh
# dotenv posix
# This line is a comment, The above line is a directive
COMMENT=This-#-is-a-character # This is a comment

UNQUOTED=value1 # Spaces and some special characters cannot be used
SINGLE_QUOTED='value 2' # Cannot use single quote
DOUBLE_QUOTED="value 3" # Some special characters need to be escaped

MULTILINE="line1
line2: \n is not a newline
line3"
LONGLINE="https://github.com/ko1nksm\
/shdotenv/blob/main/README.md"

ENDPOINT="http://${HOST}/api" # Variable expansion requires braces

export EXPORT1="value"
export EXPORT2 # Equivalent to: export EXPORT2="${EXPORT2:-}"
```

- The syntax is a subset of the POSIX shell.
- The first line is an optional directive that specifies the dialect of the .env syntax
- No spaces are allowed before or after the `=` separating the name and value
- ANSI-C style escapes are not available (i.e., `\n` is not a newline)
- **Unquoted value**
  - The special characters that can be used are `#` `%` `+` `,` `-` `.` `/` `:` `=` `@` `^` `_`
- **Single-quoted value**
  - The disallowed character is: `'`
  - It can contain newline characters.
- **Double-quoted value**
  - Variable expansion is available (only `${VAR}` style is supported)
  - The following values should be escaped with a backslash (`\`): `$` <code>\`</code> `"` `\`
  - The `\` at the end of a line value means line continuation
  - It can contain newline characters.
- An optional `export` prefix can be added to the name
- Comments at the end of a line need to be preceded by spaces before the `#`

Detailed [POSIX-compliant .env syntax specification](docs/specification.md)

### Directive

Specifies the dotenv syntanx dialect that this `.env` file.

```sh
# dotenv <DIALECT>
```

Example:

```sh
# dotenv ruby
```

### Supported dialects

The formal `.env` syntax for this project is `posix` only. The `posix` is a subset of the POSIX shell and is compatible with shell scripts. Support for other .env syntax dialects is for interoperability purposes. Compatibility will be improved gradually, but is not fully compatible. Reports of problems are welcome.

- docker: [docker](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)
- ruby: [dotenv](https://github.com/bkeepers/dotenv)
- node: [dotenv](https://github.com/motdotla/dotenv) + [dotenv-expand](https://github.com/motdotla/dotenv-expand)
- python: [python-dotenv](https://github.com/theskumar/python-dotenv)
- php: [phpdotenv](https://github.com/vlucas/phpdotenv)
- go: [godotenv](https://github.com/joho/godotenv)
- rust: [dotenv](https://github.com/dotenv-rs/dotenv)

[Comparing Dialects](docs/dialects.md)

## .shdotenv

Specifies options for shdotenv. Currently, only `dialect` is supported. It is recommended that the dotenv dialect be specified with the `dotenv` directive. The `.shdotenv` setting is for personal use in projects where it is not allowed.

```
dialect: <DIALECT>
```

Example:

```
dialect: ruby
```

## Environment Variables

| name               | description                             | default |
| ------------------ | --------------------------------------- | ------- |
| SHDOTENV_FORMAT    | Output format (`sh`, `fish`, etc.)      | `sh`    |
| SHDOTENV_AWK       | Path of the `awk` command               | `awk`   |
