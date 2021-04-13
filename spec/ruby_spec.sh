Describe "dotenv ruby parser"
  parse_env() {
    [ $# -gt 1 ] || set -- "$1" -v OVERLOAD=1
    %putsn "$1" | ( shift; awk -f ./src/parser.awk -v DIALECT="ruby" "$@" )
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
    Before "export VAR=123"

    Describe
      Parameters
        'VALUE="foo\abar"'        "VALUE='fooabar'"
        'VALUE="foo\nbar"'        "VALUE='foo${LF}bar'"
        'VALUE="foo\rbar"'        "VALUE='foo${CR}bar'"
        'FOO="$VAR"'              "FOO='123'"
        'FOO="${VAR}"'            "FOO='123'"
      End

      It "parses value the \`$1'"
        When call parse_env "$1"
        The output should eq "$2"
      End
    End
  End
End
