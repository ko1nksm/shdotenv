BEGIN {
  ex = envkeys_length = 0
  prefix = nameonly = ""

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
      nameonly = 1
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
      if (nameonly) {
        printf prefix "%s\n", envkeys[i]
      } else {
        printf prefix "%s=%s\n", envkeys[i], quotes(environ[envkeys[i]])
      }
    } else {
      ex = 1
    }
  }

  exit ex
}
