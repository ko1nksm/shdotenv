Describe "dotenv docker parser"
  parse_env() {
    [ $# -gt 1 ] || set -- "$1" -v OVERLOAD=1
    %putsn "$1" | ( shift; awk -f ./src/parser.awk -v DIALECT="docker" "$@" )
  }

  Context "when the unquoted value is given"
    Describe
      Parameters
        'FOO=value'                 "FOO='value'"
        "FOO=#value # comment"      "FOO='#value # comment'"
        "FOO=value   "              "FOO='value   '"
        'FOO='                      "FOO=''"
        'export FOO=value'          "export FOO='value'"
        "FOO=foo bar"               "FOO='foo bar'"
        "FOO=   foo"                "FOO='   foo'"
      End

      It "parses value the \`$1'"
        When call parse_env "$1"
        The output should eq "$2"
      End
    End
  End

  It "does not parse multi-line values"
    data() { %text
      #|FOO='line 1
      #|line 2'
    }
    result() { %text
      #|FOO="'line 1"
    }
    When call parse_env "$(data)"
    The status should be failure
    The error should eq "\`line 2'': not a variable definition"
  End
End
