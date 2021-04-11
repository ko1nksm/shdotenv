#!/usr/bin/awk -f

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

function expand_env(key) {
  return (key in ENVIRON) ? ENVIRON[key] : ""
}

function parse_double_quoted_value(str,  variable, new) {
  ESCAPED_CHARACTER = "\\\\."
  META_CHARACTER = "[$`\"\\\\]"
  VARIABLE_EXPANSION = "\\$[{][^}]*}"

  if (dialect("ruby|node|go")) {
    VARIABLE_EXPANSION = "\\$" IDENTIFIER "|" VARIABLE_EXPANSION
  }

  while(match(str, ESCAPED_CHARACTER "|" VARIABLE_EXPANSION "|" META_CHARACTER)) {
    pos = RSTART
    len = RLENGTH
    variable = substr(str, pos, len)

    if (match(variable, "^" META_CHARACTER "$")) {
      syntax_error("the following metacharacters must be escaped: $`\"\\")
    } else if (match(variable, "^" ESCAPED_CHARACTER "$")) {
      if (dialect("posix")) variable = unescape(variable, "$`\"\\\n", TRUE)
      if (dialect("ruby|go")) variable = unescape(variable, "nr", FALSE)
      if (dialect("node")) variable = unescape(variable, "n", TRUE)
      if (dialect("python")) variable = unescape(variable, "abfnrtv", TRUE)
      if (dialect("php")) variable = unescape(variable, "fnrtv", TRUE)
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

function parse_unquoted_value(str) {
  if (match(str, "[ \t]")) {
    syntax_error("spaces are not allowed without quoting")
  }

  if (match(str, "[][{}()<>\"'`!$&~|;\\\\*?]")) {
    syntax_error("using without quotes is not allowed: !$&()*;<>?[\\]`{|}~")
  }
  return parse_double_quoted_value(str)
}

function remove_optional_comment(value, len,  rest) {
  rest = substr(value, len + 1)
  if (match(rest, "^#.*")) {
    syntax_error("spaces are required before the end-of-line comment")
  }
  sub("^([ \t]+#.*|[ \t]*)$", "", rest)
  return substr(value, 1, len) rest
}

function unescape(str, escape, keep,  escapes, idx) {
  split(escape, escapes, "")
  for (idx in escapes) {
    escape = escapes[idx]
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

function output_key(export, key) {
  if (KEYONLY) {
    print key
  } else {
    print (export ? "export " : "unset ") key
  }
}

function output_key_value(export, key, value) {
  if (KEYONLY) {
    print key
  } else {
    if (!OVERLOAD && key in ENVIRON) return
    ENVIRON[key] = value
    gsub("'", "'\\''", value)
    print (export ? "export " : "") key "='" value "'"
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
      output_key(DOEXPORT, parse_key_only(line))
    } else {
      export = ALLEXPORT
      key = parse_key(substr(line, 1, equal_pos - 1))
      value = substr(line, equal_pos + 1)
      if (sub("^export[ \t]+", "", key)) export = DOEXPORT

      if (dialect("docker")) {
        output_key_value(export, key, value)
      } else if (match(value, "^"SQ_VALUE)) {
        value = remove_optional_comment(value, RLENGTH)
        value = parse_single_quoted_value(unquote(value, "'"))
        output_key_value(export, key, value)
      } else if (match(value, "^"DQ_VALUE)) {
        value = remove_optional_comment(value, RLENGTH)
        value = parse_double_quoted_value(unquote(value, "\""))
        output_key_value(export, key, value)
      } else {
        if (match(value, "[ \t]#")) {
          value = remove_optional_comment(value, RSTART - 1)
        }
        value = parse_unquoted_value(rtrim(value))
        output_key_value(export, key, value)
      }
    }
  }
}

BEGIN {
  IDENTIFIER="[a-zA-Z_][a-zA-Z0-9_]*"
  TRUE  = DOEXPORT = DOEXPAND = 1
  FALSE = NOEXPORT = NOEXPAND = 0

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
