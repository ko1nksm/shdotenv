Describe "formatter"
  format_as() {
    set -- "$2" -v OVERLOAD=1 -v FORMAT="$1"
    %putsn "$1" | ( shift; awk -f ./src/parser.awk "$@" )
  }

  Describe "sh"
    Parameters
      'FOO=bar'                   "FOO='bar'"
      "FOO='a\"b'"                "FOO='a\"b'"
      "FOO=\"a'b\""               "FOO=\"a'b\""
      "FOO='a${LF}b'"             "FOO='a${LF}b'"
      'export FOO'                "export FOO"
      'export FOO=BAR'            "export FOO='BAR'"
    End

    It "parses value the \`$1'"
      When call format_as sh "$1"
      The output should eq "$2"
    End
  End

  Describe "fish"
    Parameters
      'FOO=bar'                   "set FOO 'bar';"
      "FOO='a\"b'"                "set FOO 'a\"b';"
      "FOO=\"a'b\""               "set FOO 'a\'b';"
      "FOO='a${LF}b'"             "set FOO 'a${LF}b';"
      'export FOO'                'set --export FOO "$FOO";'
      'export FOO BAR'            'set --export FOO BAR "$FOO BAR";'
    End

    It "parses value the \`$1'"
      When call format_as fish "$1"
      The output should eq "$2"
    End
  End
End
