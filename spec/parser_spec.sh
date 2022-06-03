Describe "dotenv posix parser"
  parse_env() {
    [ $# -gt 1 ] || set -- "$1" -v OVERLOAD=1
    %putsn "$1" | ( shift; awk -f ./src/parser.awk "$@" )
  }

  It "does not accept unsupported dotenv dialect"
    data() { %text
      #|# dotenv unknown
      #|FOO=value
    }
    When call parse_env "$(data)"
    The status should be failure
    The error should eq 'unsupported dotenv dialect: unknown'
  End

  Context "when the double quoted value is given"
    It "expands variables"
      BeforeCall "unset VAR FOO ||:"
      data() { %text
        #|VAR=123
        #|FOO="[${VAR}]"
      }
      result() { %text
        #|VAR='123'
        #|FOO='[123]'
      }
      When call parse_env "$(data)"
      The output should eq "$(result)"
    End

    It "expands variables with exported values"
      BeforeCall "export VAR=456"
      data() { %text
        #|FOO="[${VAR}]"
      }
      result() { %text
        #|FOO='[456]'
      }
      When call parse_env "$(data)"
      The output should eq "$(result)"
    End
  End

  Context "when not in overload mode"
    It "does not overload the exported value"
      BeforeCall "export FOO=123"
      data() { %text
        #|FOO=456
      }
      When call parse_env "$(data)" -v OVERLOAD=0
      The output should eq ""
    End

    It "cannot be redefined in env file"
      BeforeCall "export FOO=123"
      data() { %text
        #|FOO=456
        #|FOO=789
      }
      When call parse_env "$(data)" -v OVERLOAD=0
      The output should eq ""
      The error should eq "/dev/stdin: \`FOO' is already defined in the /dev/stdin"
      The status should be failure
    End
  End

  Context "when in overload mode"
    It "overloads the exported value"
      BeforeCall "export FOO=123"
      data() { %text
        #|FOO=456
      }
      result() { %text
        #|FOO='456'
      }
      When call parse_env "$(data)" -v OVERLOAD=1
      The output should eq "$(result)"
    End

    It "will be overridden by later definitions"
      BeforeCall "export FOO=123"
      data() { %text
        #|FOO=456
        #|FOO=789
      }
      result() { %text
        #|FOO='789'
      }
      When call parse_env "$(data)" -v OVERLOAD=1
      The output should eq "$(result)"
    End
  End
End
