function getopts(optstring, args,  opt, oarg, i, j) {
  i = int(OPTIND)
  j = int(substr(OPTIND, length(i) + 2))
  if (! (i in args)) return ""
  if (args[i] == "--") { OPTIND = i + 1; return "" }
  if (args[i] !~ /^-./) return ""
  opt = substr(args[i], j + 2, 1)
  oarg = substr(args[i], j + 3)
  if (index(optstring, opt ":")) {
    if (oarg == "") {
      if ( (i + 1) in args ) {
        OPTARG = args[i + 1]
        OPTIND = i + 2
      } else {
        OPTARG = "option requires an argument -- " opt
        opt = "?"
      }
    } else {
      OPTARG = oarg
      OPTIND = i + 1
    }
  } else if (index(optstring, opt)) {
    OPTARG = ""
    OPTIND = (oarg == "") ? (i + 1) : (i "," (j + 1))
  } else {
    OPTARG = "illegal option -- " opt
    opt = "?"
  }
  return opt
}

function prinit(str) {
  PRCHECK="(PATH=/dev/null; print \" -n\" 2>/dev/null) || printf -- f"
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
  SH = "sh"; NUL = "\\0"; CR = "\\r"; LF = "\\n"
  newline = LF
  ex = envkeys_length = 0
  prefix = mode = silent = ""

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

  OPTIND = i
  while(OPT = getopts("pnvs0", ARGV)) {
    if (OPT == "p") prefix = "export "
    if (OPT == "n") mode = "name"
    if (OPT == "v") mode = "value"
    if (OPT == "0") newline = NUL
    if (OPT == "s") silent = 1
    if (OPT == "?") abort("export: " OPTARG)
  }
  i = OPTIND

  if (i < ARGC) {
    envkeys_length = 0
    for (; i < ARGC; i++) {
      envkeys[envkeys_length++] = ARGV[i]
    }
  } else {
    sort(envkeys)
  }

  # Pre-check
  for (i = 0; i < envkeys_length; i++ ) {
    key = envkeys[i]
    if (!match(key, "^[a-zA-Z_][a-zA-Z0-9_]*$")) {
      error("export: Invalid environment variable name: " key)
      ex = 1
    } else if (key in environ) {
      value = environ[key]
      if (mode == "value") {
        if (newline != NUL && index(value, "\n") > 0) {
          error("export: Use the -0 option to output value containing newline: " key)
          ex = 1
        }
      }
    } else if (silent) {
      environ[key] = ""
    } else {
      error("export: The specified name cannot be found: " key)
      ex = 1
    }
  }

  if (ex != 0) exit ex

  if (newline == NUL) prinit()
  for (i = 0; i < envkeys_length; i++ ) {
    key = envkeys[i]
    value = environ[key]
    if (mode == "name") {
      line = prefix key
    } else if (mode == "value") {
      line = value
    } else {
      line = prefix key "=" quotes(value)
    }

    if (newline == NUL) {
      pr(line, newline)
    } else {
      print line
    }
  }

  exit ex
}
