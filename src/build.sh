#!/bin/sh

set -eu

if [ "${MINIFY:-}" ]; then
  minify_awk() {
    while IFS= read -r line; do
      # shellcheck disable=SC2295
      line=${line#"${line%%[!$IFS]*}"}
      case $line in "#"* | "") continue ;; esac
      printf '%s\n' "$line"
    done
  }
  minify_sh() {
    shfmt -mn -ln posix
  }
else
  minify_awk() { cat; }
  minify_sh() { cat; }
fi

while IFS= read -r line; do
  case $line in
    *"# @INCLUDE-FILE")
      varname=${line%%=*} cmd=${line#*=} data=""
      eval "data=$cmd"
      {
        printf "%s='" "$varname"
        printf '%s' "$data" | sed "s/'/'\\\\''/g"
        echo "'"
      } | minify_awk
      ;;
    *) printf '%s\n' "$line" ;;
  esac
done | minify_sh
