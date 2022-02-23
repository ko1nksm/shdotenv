function abort(msg) {
  print msg > "/dev/stderr"
  exit 1
}

function quotes(value) {
  if (match(value, /'/)) {
    gsub(/[$`"\\]/, "\\\\&", value)
    return "\"" value "\""
  }
  return "'" value "'"
}

function sort(ary,  len, min, tmp, i, j) {
  len = 0
  for (i in ary) len++
  for (i = 0; i < len - 1; i++) {
    min = i
    for (j = i + 1; j < len; j++) {
      if (ary[min] > ary[j]) min = j
    }
    tmp = ary[min]
    ary[min] = ary[i]
    ary[i] = tmp
  }
}

BEGIN {
  ex = envkeys_length = 0
  prefix = ""

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
    } else if (ARGV[i] == "--") {
      i++
      break
    } else if (substr(ARGV[i], 1, 1) == "-") {
      abort("shdotenv export: Unknown option: " ARGV[i])
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
      printf prefix "%s=%s\n", envkeys[i], quotes(environ[envkeys[i]])
    } else {
      ex = 1
    }
  }

  exit ex
}
