# shellcheck shell=sh

# Defining variables and functions here will affect all specfiles.
# Change shell options inside a function may cause different behavior,
# so it is better to set them here.
set -eu

SHDOTENV_AWK=${SHDOTENV_AWK:-awk}

# This callback function will be invoked only once before loading specfiles.
spec_helper_precheck() {
  # Available functions: info, warn, error, abort, setenv, unsetenv
  # Available variables: VERSION, SHELL_TYPE, SHELL_VERSION
  : minimum_version "0.29.0"

  if ! env "$SHDOTENV_AWK" "" 2>/dev/null; then
    abort "awk not found"
  fi
}

# This callback function will be invoked after a specfile has been loaded.
spec_helper_loaded() {
  :
}

# This callback function will be invoked after core modules has been loaded.
spec_helper_configure() {
  # Available functions: import, before_each, after_each, before_all, after_all
  : import 'support/custom_matcher'
  BEL=$SHELLSPEC_BEL  # \a 0x07
  BS=$SHELLSPEC_BS    # \b 0x08
  HT=$SHELLSPEC_HT    # \t 0x09
  FF=$SHELLSPEC_FF    # \f 0x0c
  LF=$SHELLSPEC_LF    # \n 0x0A
  VT=$SHELLSPEC_VT    # \v 0x0B
  CR=$SHELLSPEC_CR    # \r 0x0D

  if [ "${SHDOTENV_AWK##*/}" = "gawk" ]; then
    awk() { env "$SHDOTENV_AWK" "$@"; }
  elif env "$SHDOTENV_AWK" -V > /dev/null 2>&1; then
    awk() { env "$SHDOTENV_AWK" --traditional "$@"; }
  else
    awk() { env "$SHDOTENV_AWK" "$@"; }
  fi
}
