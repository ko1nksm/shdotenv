# POSIX-compliant .env syntax specification

POSIX-compliant .env syntax is subset of POSIX shell scripts

## File format

### The encoding is UTF-8

UTF-8 is already widespread and there is no need to support other encodings.

### The newline code is LF only

POSIX shells treats CR as a character.

```sh
# when the newline code is CR LF
FOO=123
echo "${#FOO}" # => 4
```

### The first line is a directive to distinguish between .env syntax dialects

```sh
# dotenv posix
FOO=123
```

### Cannot contain null characters

The shell cannot handle the null (`\0`) character.

## Environment variable name

### The key must be followed by `=`

POSIX shell specification

**Valid**

```sh
FOO=
```

**Invalid**

```sh
FOO
```

### Spaces or tabs can be inserted before the name

POSIX shell specification.

**Valid**

```sh
    FOO=123
```

### No spaces or tabs around `=`

POSIX shell specification.

**Invalid**

```sh
FOO   =123
BAR=   123
```

### The name must be `[a-zA-Z_][a-zA-Z0-9_]*`

POSIX shell specification.

**Invalid**

```sh
FOO.BAR.BAZ=123
1ABC=123
```

### The name can have an export prefix

Many dotenv implementations support it.

**Valid**

```sh
export FOO=123
export BAR # Same as `export BAR="${BAR:-}"`
```

## Comment

### Lines beginning with `#` are comments

POSIX shell specification.

**Valid**

```sh
# comment
    # comment
```

### Comment after the value must have spaces or tabs before the `#`

POSIX shell specification.

**Valid**

```sh
FOO=123 # this is comment
BAR='123' # this is comment
BAZ="123" # this is comment
```

**Invalid**

```sh
FOO=123#this-is-not-comment
BAR='123'#this-is-not-comment
BAZ="123"#this-is-not-comment
```

## Unquoted value

### Cannot contain spaces or tabs

POSIX shell specification.

**Invalid**

```sh
FOO=123 456
```

### Some symbols cannot be used

The following characters have a special meaning in shell scripts and cannot be used without quotes.

```
[ ] { } ( ) < > " ' ` ! $ & ~ | ; \ * ?
```

In the POSIX shell specification, it can be used by escaping it with a backslash, but it is better to use quotes.

**Invalid**

```sh
URL=http://example.com?name1=value1&name2=value2
```

Note: `#` (without preceding spaces or tabs) can be used as a character.

**Valid**

```sh
URL1='http://example.com?name1=value1&name2=value2'
URL2=http://example.com/index.html#this-is-hash #this-is-comment
```

### Variable expansion is not available

The behavior is different for different shells, so it is not portable.

```sh
VAR="foo bar"
export VALUE=$VAR
echo "$VALUE"
# => dash, posh, yash: `foo`
# => bash, ksh, mksh, zsh: `foo bar`
```

## Single-quoted value

### The value cannot contain single quotes

POSIX shell specification. Use double quotes.

**Invalid**

```
VAR1='foo'bar'
VAR2='foo\'bar'
```

### Cannot use variable expansion

POSIX shell specification.

**Invalid**

```
VAR='${FOO}' # this is just a string
```

### Newlines can be inserted

**Valid**

```
VAR='line1
line2'
```

## Not possible to close quotes in the middle of a line

This is possible in POSIX shell specification, but prohibited for simplicity of the specification.

**Invalid**

```
VAR='foo''bar'
```

## Double-quoted value

### Escaping is required when using `"` <code>\`</code> `\` `$` as a value

POSIX shell specification.

**Invalid**

```
VAR=" " ` \ $ "
```

**Valid**

```sh
VAR=" \" \` \\ \$ "
```

### Except for the above, backslashes are not escape characters

POSIX shell specification.

```sh
VAR=" \a \r \n "
printf '%s' "$VAR" # => \a \r \n
```

NOTE: Do not investigate with `echo`. In some shells, `echo` may interpret escape characters.

### The `\` at the end of the line means line continuation

POSIX shell specification.

```sh
LONGLINE="https://github.com/ko1nksm\
/shdotenv/blob/main/README.md"

echo "$LONGLINE" # => https://github.com/ko1nksm/shdotenv/blob/main/README.md
```

### Variable expansion is supported

POSIX shell specification.

**Valid**

```sh
BAR="bar"
VALUE="foo ${BAR} baz"
```

### Braces are required for variable expansion

If there are no braces, the behavior may vary depending on the shell.

```sh
BAR="bar"
VALUE="foo $BAR[0] baz"
# => bash: foo bar[0] baz
# => zsh: foo  baz
```

### If the variable is not set, it treats as an empty string

POSIX shell specification

```sh
unset BAR
VALUE="foo ${BAR} baz"
echo "$VALUE" # => foo  baz
```

### Command substitution is not supported

It is not supported due to its complexity and the security risk of random command execution.
