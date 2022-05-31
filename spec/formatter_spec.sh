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
      'export FOO=BAR'            "set --export FOO 'BAR';"
    End

    It "parses value the \`$1'"
      When call format_as fish "$1"
      The output should eq "$2"
    End
  End

  Describe "csh"
    Parameters
      'FOO=bar'                   "set FOO='bar';"
      "FOO='a\"b'"                "set FOO='a\"b';"
      "FOO=\"a'b\""               "set FOO=\"a'b\";"
      "FOO='a${LF}b'"             "set FOO=\"a\${newline:q}b\";"
      'export FOO'                'setenv FOO;'
      'export FOO=BAR'            "setenv FOO 'BAR';"
    End

    It "parses value the \`$1'"
      When call format_as csh "$1"
      The output should eq "$2"
    End
  End

  Describe "json"
    Parameters
      'FOO=bar'                   "{$LF"'  "FOO": "bar"'"$LF}"
      "FOO=foo${LF}BAR=bar"       "{$LF"'  "FOO": "foo",'"${LF}"'  "BAR": "bar"'"$LF}"
      "FOO='a\"b'"                "{$LF"'  "FOO": "a\"b"'"$LF}"
      "FOO=\"a'b\""               "{$LF"'  "FOO": "a'"'"'b"'"$LF}"
      "FOO='a${LF}${CR}${LF}b'"   "{$LF"'  "FOO": "a\n\r\nb"'"$LF}"
      "FOO='a${BS}${HT}${FF}b'"   "{$LF"'  "FOO": "a\b\t\fb"'"$LF}"
      "FOO='a\"\\b'"              "{$LF"'  "FOO": "a\"\\b"'"$LF}"
      'export FOO'                "{$LF"'  "FOO": ""'"$LF}"
      'export FOO=BAR'            "{$LF"'  "FOO": "BAR"'"$LF}"
    End

    It "parses value the \`$1'"
      When call format_as json "$1"
      The output should eq "$2"
    End
  End

  Describe "jsonl"
    Parameters
      'FOO=bar'                   '{ "FOO": "bar" }'
      "FOO=foo${LF}BAR=bar"       '{ "FOO": "foo", "BAR": "bar" }'
      "FOO='a\"b'"                '{ "FOO": "a\"b" }'
      "FOO=\"a'b\""               '{ "FOO": "a'"'"'b" }'
      "FOO='a${LF}${CR}${LF}b'"   '{ "FOO": "a\n\r\nb" }'
      "FOO='a${BS}${HT}${FF}b'"   '{ "FOO": "a\b\t\fb" }'
      "FOO='a\"\\b'"              '{ "FOO": "a\"\\b" }'
      'export FOO'                '{ "FOO": "" }'
      'export FOO=BAR'            '{ "FOO": "BAR" }'
    End

    It "parses value the \`$1'"
      When call format_as jsonl "$1"
      The output should eq "$2"
    End
  End
End
