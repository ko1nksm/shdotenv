#!/bin/sh

set -eu

minify() {
  while IFS= read -r line; do
    line=${line#"${line%%[!$IFS]*}"}
    case $line in "#"* | "") continue ;; esac
    printf '%s\n' "$line"
  done
}

while IFS= read -r line; do
  case $line in
    *"# @INCLUDE-FILE")
      varname=${line%%=*} cmd=${line#*=} data=""
      eval "data=$cmd"
      {
        printf "%s='" "$varname"
        printf '%s' "$data" | sed "s/'/'\\\\''/g"
        echo "'"
      } | minify
      ;;
    *) printf '%s\n' "$line" ;;
  esac
done | {
  echo "#!/bin/sh"
  echo "# Copyright (c) 2021 Koichi Nakashima"
  echo "# shdotenv is released under the MIT license"
  echo "# https://opensource.org/licenses/MIT"
  shfmt -mn -ln posix
}
