#!/usr/bin/awk -f

function abort(msg) {
  print msg > "/dev/stderr"
  exit 1
}

function syntax_error(msg) {
  sub("[\n]+$", "", CURRENT_LINE)
  abort(sprintf("`%s': %s", CURRENT_LINE, msg))
}

function trim(str) {
  sub("(^[ \t]+)|([ \t]+$)", "", str)
  return str
}

function chomp(str) {
  sub("\n$", "", str)
  return str
}

function dialect(name) {
  return index("|" name "|", "|" DIALECT "|") > 0
}

function unescape(str, escape, keep_backslash,  escapes, idx) {
  split(escape, escapes, "")
  for (idx in escapes) {
    escape = escapes[idx]
    if (str == "\\" escape) return ESCAPE[escape]
  }
  return (keep_backslash ? str : substr(str, 2))
}

function unquote(str, quote) {
  if (match(str, "^" quote ".*" quote "$")) {
    gsub("^['\"]|['\"]$", "", str)
    return str
  }
  syntax_error("unterminated quoted string")
}

function expand_env(key) {
  return (key in environ) ? environ[key] : ""
}

function parse_key(key) {
  if (dialect("ruby|node|python|php|go")) {
    key = trim(key)
  }
  if (match(key, "(^[ \t]+|[ \t]+$)")) {
    abort(sprintf("`%s': no space allowed after the key", key))
  }
  if (!match(key, "^(export[ \t]+)?" IDENTIFIER "$")) {
    abort(sprintf("`%s': the key is not a valid identifier", key))
  }
  return key
}

function parse_key_only(str) {
  if (!sub("^export[ \t]+", "", str)) {
    syntax_error("not a variable definition")
  }
  sub("[ \t]#.*", "", str)
  if (!match(str, "^(" IDENTIFIER "[ \t]*)+$")) {
    abort(sprintf("`%s': the key is not a valid identifier", str))
  }
  return str
}

function parse_raw_value(str) {
  return str
}

function parse_unquoted_value(str) {
  if (dialect("posix")) {
    if (match(str, "[ \t]")) {
      syntax_error("spaces are not allowed without quoting")
    }

    if (match(str, "[][{}()<>\"'`!$&~|;\\\\*?]")) {
      syntax_error("using without quotes is not allowed: !$&()*;<>?[\\]`{|}~")
    }
  } else {
    str = trim(str)
  }

  return expand_value(str, NO_QUOTES)
}

function parse_single_quoted_value(str) {
  if (index(str, "'")) {
    syntax_error("using single quote not allowed in the single quoted value")
  }
  return str
}

function parse_double_quoted_value(str) {
  return expand_value(str, DOUBLE_QUOTES)
}

function expand_value(str, quote,  variable, new) {
  ESCAPED_CHARACTER = "\\\\."
  META_CHARACTER = "[$`\"\\\\]"
  VARIABLE_EXPANSION = "\\$[{][^}]*}"

  if (dialect("ruby|node|go|rust")) {
    VARIABLE_EXPANSION = "\\$" IDENTIFIER "|" VARIABLE_EXPANSION
  }

  while(match(str, ESCAPED_CHARACTER "|" VARIABLE_EXPANSION "|" META_CHARACTER)) {
    pos = RSTART
    len = RLENGTH
    variable = substr(str, pos, len)

    if (quote == DOUBLE_QUOTES) {
      if (match(variable, "^" META_CHARACTER "$")) {
        syntax_error("the following metacharacters must be escaped: $`\"\\")
      }

      if (match(variable, "^" ESCAPED_CHARACTER "$")) {
        if (dialect("posix")) variable = unescape(variable, "$`\"\\\n", KEEP)
        if (dialect("ruby|go")) variable = unescape(variable, "nr", NO_KEEP)
        if (dialect("node|rust")) variable = unescape(variable, "n", KEEP)
        if (dialect("python")) variable = unescape(variable, "abfnrtv", KEEP)
        if (dialect("php")) variable = unescape(variable, "fnrtv", KEEP)
      }
    }

    if (match(variable, "^\\$" IDENTIFIER "$")) {
      variable = expand_env(substr(variable, 2))
    } else if (match(variable, "^\\$[{]" IDENTIFIER "}$")) {
      variable = expand_env(substr(variable, 3, length(variable) - 3))
    } else if (match(variable, "^" VARIABLE_EXPANSION "$")) {
      if (!match(variable, "^\\$[{]" IDENTIFIER "}$")) {
        syntax_error("the variable name is not a valid identifier")
      }
    }
    new = new substr(str, 1, pos - 1) variable
    str = substr(str, pos + len)
  }
  return new str
}

function remove_optional_comment(value, len,  rest) {
  rest = substr(value, len + 1)
  if (match(rest, "^#.*")) {
    syntax_error("spaces are required before the end-of-line comment")
  }
  sub("^([ \t]+#.*|[ \t]*)$", "", rest)
  return substr(value, 1, len) rest
}

function output(flag, key, value) {
  if (FORMAT == "sh") output_sh(flag, key, value)
  if (FORMAT == "fish") output_fish(flag, key, value)
}

function output_sh(flag, key, value) {
  if (match(value, /'/)) {
    gsub(/[$`"\\]/, "\\\\&", value)
    value = "\"" value "\""
  } else {
    value = "'" value "'"
  }

  if (flag == ONLY_EXPORT) print "export " key
  if (flag == DO_EXPORT) print "export " key "=" value
  if (flag == NO_EXPORT) print key "=" value
}

function output_fish(flag, key, value) {
  gsub(/[\\']/, "\\\\&", value)
  if (flag == ONLY_EXPORT) print "set --export " key " \"$" key "\";"
  if (flag == DO_EXPORT) print "set --export " key " '" value "';"
  if (flag == NO_EXPORT) print "set " key " '" value "';"
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
      key = parse_key_only(line)
    } else {
      key = parse_key(substr(line, 1, equal_pos - 1))
    }

    if (NAMEONLY) {
      if (!OVERLOAD && key in environ) continue
      print key
      environ[key] = ""
    } else if (equal_pos == 0) {
      output(ONLY_EXPORT, key)
    } else {
      export = (ALLEXPORT ? DO_EXPORT : NO_EXPORT)
      if (sub("^export[ \t]+", "", key)) export = DO_EXPORT
      value = substr(line, equal_pos + 1)

      if (dialect("docker")) {
        value = parse_raw_value(value)
      } else if (match(value, "^"SQ_VALUE)) {
        value = remove_optional_comment(value, RLENGTH)
        value = parse_single_quoted_value(unquote(value, "'"))
      } else if (match(value, "^"DQ_VALUE)) {
        value = remove_optional_comment(value, RLENGTH)
        value = parse_double_quoted_value(unquote(value, "\""))
      } else {
        if (match(value, "[ \t]#")) {
          value = remove_optional_comment(value, RSTART - 1)
        }
        value = parse_unquoted_value(trim(value))
      }
      if (!OVERLOAD && key in environ) continue
      environ[key] = value
      if (match(key, GREP)) output(export, key, value)
    }
  }
}

BEGIN {
  IDENTIFIER = "[a-zA-Z_][a-zA-Z0-9_]*"
  KEEP = 1; NO_KEEP = 0
  ONLY_EXPORT = 0; DO_EXPORT = 1; NO_EXPORT = 2
  NO_QUOTES = 0; SINGLE_QUOTES = 1; DOUBLE_QUOTES = 2

  ESCAPE["$"] = "$"
  ESCAPE["`"] = "`"
  ESCAPE["\""] = "\""
  ESCAPE["\\"] = "\\"
  ESCAPE["\n"] = ""
  ESCAPE["a"] = "\a"
  ESCAPE["b"] = "\b"
  ESCAPE["f"] = "\f"
  ESCAPE["n"] = "\n"
  ESCAPE["r"] = "\r"
  ESCAPE["t"] = "\t"
  ESCAPE["v"] = "\v"

  if (!IGNORE) {
    for (key in ENVIRON) {
      environ[key] = ENVIRON[key]
    }
  }

  if (FORMAT == "") FORMAT = "sh"
  if (!match(FORMAT, "^(sh|fish)$")) {
    abort("unsupported format: " FORMAT)
  }

  if (ARGC == 1) {
    ARGV[1] = "/dev/stdin"
    ARGC = 2
  }
  for (i = 1; i < ARGC; i++) {
    getline < ARGV[i]
    lines = $0 "\n"
    if (DIALECT == "" && sub("^# dotenv ", "")) DIALECT = $0
    if (DIALECT == "") DIALECT = "posix"
    if (!dialect("posix|docker|ruby|node|python|php|go|rust")) {
      abort("unsupported dotenv dialect: " DIALECT)
    }
    while (getline < ARGV[i] > 0) {
      lines = lines $0 "\n"
    }
    if (!match(ARGV[i], "^(/dev/stdin|-)$")) close(ARGV[i])
    parse(lines)
  }
  exit
}
