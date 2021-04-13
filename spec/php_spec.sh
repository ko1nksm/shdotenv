Describe "dotenv php parser"
  parse_env() {
    [ $# -gt 1 ] || set -- "$1" -v OVERLOAD=1
    %putsn "$1" | ( shift; awk -f ./src/parser.awk -v DIALECT="php" "$@" )
  }

  Context "when the key is given"
    Describe
      Parameters
        '  FOO=bar'                 "FOO='bar'"
        'FOO  =bar'                 "FOO='bar'"
      End

      It "parses value the \`$1'"
        When call parse_env "$1"
        The output should eq "$2"
      End
    End
  End

  Context "when the unquoted value is given"
    Describe
      Parameters
        'FOO=value'                             "FOO='value'"
        "FOO=value   "                          "FOO='value'"
        'FOO=foo bar'                           "FOO='foo bar'"
        'FOO=foo\nbar'                          "FOO='foo\nbar'"
        'FOO=!"$%&()*+,-./:;<=>?@[\]^_`{|}~'\'  "FOO='!\"\$%&()*+,-./:;<=>?@[\]^_\`{|}~'\'"
      End

      It "parses value the \`$1'"
        When call parse_env "$1"
        The output should eq "$2"
      End
    End
  End

  Context "when the double quoted value is given"
    Describe
      Parameters
        'VALUE="foo\fbar"'        "VALUE='foo${FF}bar'"
        'VALUE="foo\nbar"'        "VALUE='foo${LF}bar'"
        'VALUE="foo\rbar"'        "VALUE='foo${CR}bar'"
        'VALUE="foo\tbar"'        "VALUE='foo${HT}bar'"
        'VALUE="foo\vbar"'        "VALUE='foo${VT}bar'"
        'VALUE="foo\zbar"'        "VALUE='foo\zbar'"
      End

      It "parses value the \`$1'"
        When call parse_env "$1"
        The output should eq "$2"
      End
    End
  End
End
