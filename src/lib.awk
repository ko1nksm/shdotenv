function error(msg) {
  print PROGNAME ": " msg > "/dev/stderr"
}

function abort(msg) {
  error(msg)
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
