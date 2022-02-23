#!/bin/sh

set -eu

minify() {
  while IFS= read -r line; do
    # shellcheck disable=SC2295
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
done
