function prinit(str) {
  PRCHECK="(PATH=/dev/null; print \" -n\" 2>/dev/null) || printf -- f"
  SH = "sh"; NUL = "\\0"; CR = "\\r"; LF = "\\n"
  (SH " -c \047" PRCHECK "\047") | getline CMD
  CMD = "print" (CMD == "--" ? "f " : CMD " -- ")
}

function pr(str, eol) {
  gsub(/\\/, "&&", str)
  gsub(/%/, "\\045", str)
  gsub(/\047/, "\047\\\047\047", str)
  print CMD "\047" str eol "\047" | SH
}

BEGIN {
  prinit(); newline = LF
  ex = envkeys_length = 0
  prefix = mode = ""

  for (key in ENVIRON) {
    if (!match(key, "^[a-zA-Z_][a-zA-Z0-9_]*$")) continue
    if (match(key, /^(AWKPATH|AWKLIBPATH)$/)) continue
    environ[key] = ENVIRON[key]
    envkeys[envkeys_length++] = key
  }

  for (i = 1; i < ARGC; i++) {
    if (ARGV[i] == "-") {
      i++
      break
    }
    if (match(ARGV[i], "=")) {
      key = substr(ARGV[i], 1, RSTART - 1)
      value = substr(ARGV[i], RSTART + 1)
      environ[key] = value
      envkeys[envkeys_length++] = key
    }
  }

  for (; i < ARGC; i++) {
    if (ARGV[i] == "-p") {
      prefix = "export "
    } else if (ARGV[i] == "-n") {
      mode = "name"
    } else if (ARGV[i] == "-v") {
      mode = "value"
    } else if (ARGV[i] == "-0") {
      newline = NUL
    } else if (ARGV[i] == "--") {
      i++
      break
    } else if (substr(ARGV[i], 1, 1) == "-") {
      abort("export: Unknown option: " ARGV[i])
    } else {
      break
    }
  }

  if (i < ARGC) {
    envkeys_length = 0
    for (; i < ARGC; i++) {
      envkeys[envkeys_length++] = ARGV[i]
    }
  } else {
    sort(envkeys)
  }

  for (i = 0; i < envkeys_length; i++ ) {
    if (envkeys[i] in environ) {
      key = envkeys[i]; value = environ[key]
      if (mode == "name") {
        pr(prefix key, newline)
      } else if (mode == "value") {
        if (newline != NUL && index(value, "\n") > 0) {
          error("export: Use the -0 option to output value containing newline: " key)
          value = ""
          ex = 1
        }
        pr(prefix value, newline)
      } else {
        pr(prefix key "=" quotes(value), newline)
      }
    } else {
      pr("", newline)
      ex = 1
    }
  }

  exit ex
}
