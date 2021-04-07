Describe "dotenv ruby parser"
  parse_env() {
    [ $# -gt 1 ] || set -- "$1" -v OVERLOAD=1
    %putsn "$1" | ( shift; awk -f ./src/parser.awk -v DIALECT="ruby" "$@" )
  }

  Context "when the key is given"
    Describe
      Parameters
        '  FOO=bar'                 'FOO="bar"'
        'FOO  =bar'                 'FOO="bar"'
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
        'VALUE="foo\abar"'        'VALUE="fooabar"'
        'VALUE="foo\nbar"'        'VALUE="foo'"$LF"'bar"'
        'VALUE="foo\rbar"'        'VALUE="foo'"$CR"'bar"'
        'FOO="$VAR"'              'FOO="${VAR:-}"'
      End

      It "parses value the \`$1'"
        When call parse_env "$1"
        The output should eq "$2"
      End
    End
  End
End
