#!/usr/bin/awk -f

# MIT License
#
# Copyright (c) 2021 Koichi Nakashima
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

function abort(msg) {
  print msg > "/dev/stderr"
  exit 1
}

function syntax_error(msg) {
  sub("[\n]+$", "", CURRENT_LINE)
  abort(sprintf("`%s': %s", CURRENT_LINE, msg))
}

function dialect(name) {
  return index("|" name "|", "|" DIALECT "|") > 0
}

function parse_key(key) {
  if (dialect("ruby|node|python|php|go")) {
    key = rtrim(key)
  }
  if (match(key, "(^[ \t]+|[ \t]+$)")) {
    abort(sprintf("`%s': no space allowed after the key", key))
  }
  if (!match(key, "^(export[ \t]+)?" IDENTIFIER "$")) {
    abort(sprintf("`%s': the key is not a valid identifier", key))
  }
  return key
}

function parse_key_only(key) {
  sub("[ \t]#.*", "", key)
  if (!match(key, "^(" IDENTIFIER "[ \t]*)+$")) {
    abort(sprintf("`%s': the key is not a valid identifier", key))
  }
  return key
}

function parse_single_quoted_value(str) {
  if (index(str, "'")) {
    syntax_error("using single quote not allowed in the single quoted value")
  }
  return str
}

function parse_double_quoted_value(str, _variable, _new, _word) {
  ESCAPED_CHARACTER = "\\\\."
  META_CHARACTER = "[$`\"\\\\]"
  VARIABLE_EXPANSION = "\\$[{][^}]*}"

  if (dialect("ruby|node|go")) {
    VARIABLE_EXPANSION = "\\$" IDENTIFIER "|" VARIABLE_EXPANSION
  }

  while(match(str, ESCAPED_CHARACTER "|" VARIABLE_EXPANSION "|" META_CHARACTER)) {
    pos = RSTART
    len = RLENGTH
    _variable = substr(str, pos, len)

    if (match(_variable, "^" META_CHARACTER "$")) {
      syntax_error("the following metacharacters must be escaped: $`\"\\")
    } else if (match(_variable, "^" ESCAPED_CHARACTER "$")) {
      if (dialect("ruby|go")) _variable = unescape(_variable, "nr", FALSE)
      if (dialect("node")) _variable = unescape(_variable, "n", TRUE)
      if (dialect("python")) _variable = unescape(_variable, "abfnrtv", TRUE)
      if (dialect("php")) _variable = unescape(_variable, "fnrtv", TRUE)
    }

    if (match(_variable, "^\\$" IDENTIFIER "$")) {
      _variable = "${" substr(_variable, 2) ":-}"
    } else if (match(_variable, "^\\$[{]" IDENTIFIER "}$")) {
      _variable = substr(_variable, 1, length(_variable) - 1) ":-}"
    } else if (match(_variable, "^" VARIABLE_EXPANSION "$")) {
      if (!match(_variable, "^\\$[{]" IDENTIFIER "}$")) {
        syntax_error("the variable name is not a valid identifier")
      }
    }
    _new = _new substr(str, 1, pos - 1) _variable
    str = substr(str, pos + len)
  }
  return _new str
}

function parse_raw_value(str) {
  gsub("'", "'\\''", str)
  return str
}

function parse_unquoted_value(str) {
  if (match(str, "[ \t]")) {
    syntax_error("spaces are not allowed without quoting")
  }

  if (match(str, "[{}\\[()<>\"'`!$&~|;\\\\*?]|]")) {
    syntax_error("using without quotes is not allowed: {}[]()<>\"'`!$&~|;\\*?")
  }
  return parse_double_quoted_value(str)
}

function remove_optional_comment(value, len, _rest) {
  _rest = substr(value, len + 1)
  if (match(_rest, "^#.*")) {
    syntax_error("spaces are required before the end-of-line comment")
  }
  sub("^([ \t]+#.*|[ \t]*)$", "", _rest)
  return substr(value, 1, len) _rest
}

function unescape(str, escape, keep, _escape, _idx) {
  split(escape, _escape, "")
  for (_idx in _escape) {
    escape = _escape[_idx]
    if (str == "\\" escape) return ESCAPE[escape]
  }
  return (keep ? str : substr(str, 2))
}

function unquote(str, quote) {
  if (match(str, "^" quote ".*" quote "$")) {
    gsub("^['\"]|['\"]$", "", str)
    return str
  }
  syntax_error("unterminated quoted string")
}

function rtrim(str) {
  sub("[ \t]+$", "", str)
  return str
}

function chomp(str) {
  sub("\n$", "", str)
  return str
}

function output(export, key, expand, value, overload, _quote) {
  if (KEYONLY) {
    print key
  } else if (length(expand) == 0) {
    print (export ? "export " : "unset ") key
  } else {
    if (!overload) printf "[ \"${" key "+x}\" ] || "
    if (export) printf "export "
    _quote = (expand ? "\"" : "'")
    print key "=" _quote value _quote
  }
}

function parse(lines) {
  SQ_VALUE = "'[^\\\\']*'?"
  DQ_VALUE = "\"(\\\\\"|[^\"])*[\"]?"
  NQ_VALUE = "[^\n]+"

  if (dialect("docker")) {
    LINE = NQ_VALUE
  } else {
    LINE = SQ_VALUE "|" DQ_VALUE "|" NQ_VALUE
  }

  while (length(lines) > 0) {
    if (sub("^[ \t\n]+", "", lines)) continue
    if (sub("^#([^\n]+)?(\n|$)", "", lines)) continue
    if (!match(lines, "^([^=\n]*=(" LINE ")?[^\n]*([\n]|$)|[^\n]*)")) {
      abort(sprintf("`%s': parse error", lines))
    }
    CURRENT_LINE = line = chomp(substr(lines, RSTART, RLENGTH))
    lines = substr(lines, RSTART + RLENGTH)
    equal_pos = index(line, "=")
    if (equal_pos == 0) {
      if (!sub("^export[ \t]+", "", line)) {
        syntax_error("not a variable definition")
      }
      output(DOEXPORT, parse_key_only(line))
    } else {
      export = ALLEXPORT
      key = parse_key(substr(line, 1, equal_pos - 1))
      value = substr(line, equal_pos + 1)
      if (sub("^export[ \t]+", "", key)) export = DOEXPORT

      if (dialect("docker")) {
        value = parse_raw_value(value)
        output(export, key, NOEXPAND, value, OVERLOAD)
      } else if (match(value, "^"SQ_VALUE)) {
        value = remove_optional_comment(value, RLENGTH)
        value = parse_single_quoted_value(unquote(value, "'"))
        output(export, key, NOEXPAND, value, OVERLOAD)
      } else if (match(value, "^"DQ_VALUE)) {
        value = remove_optional_comment(value, RLENGTH)
        value = parse_double_quoted_value(unquote(value, "\""))
        output(export, key, DOEXPAND, value, OVERLOAD)
      } else {
        if (match(value, "[ \t]#")) {
          value = remove_optional_comment(value, RSTART - 1)
        }
        value = parse_unquoted_value(rtrim(value))
        output(export, key, DOEXPAND, value, OVERLOAD)
      }
    }
  }
}

BEGIN {
  IDENTIFIER="[a-zA-Z_][a-zA-Z0-9_]*"
  TRUE  = DOEXPORT = DOEXPAND = 1
  FALSE = NOEXPORT = NOEXPAND = 0

  ESCAPE["a"] = "\a"
  ESCAPE["b"] = "\b"
  ESCAPE["f"] = "\f"
  ESCAPE["n"] = "\n"
  ESCAPE["r"] = "\r"
  ESCAPE["t"] = "\t"
  ESCAPE["v"] = "\v"

  if (ARGC == 1) {
    ARGV[1] = "/dev/stdin"
    ARGC = 2
  }
  for (i = 1; i < ARGC; i++) {
    getline < ARGV[i]
    lines = $0 "\n"
    if (DIALECT == "" && sub("^# dotenv ", "")) DIALECT = $0
    if (DIALECT == "") DIALECT = "posix"
    if (!dialect("posix|docker|ruby|node|python|php|go")) {
      abort("unsupported dotenv dialect: " DIALECT)
    }
    while (getline < ARGV[i] > 0) {
      lines = lines $0 "\n"
    }
    if (ARGV[i] != "/dev/stdin") close(ARGV[i])
    parse(lines)
  }
  exit
}
