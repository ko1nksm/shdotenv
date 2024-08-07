Describe "dotenv posix parser"
  parse_env() {
    [ $# -gt 1 ] || set -- "$1" -v OVERLOAD=1
    %putsn "$1" | ( shift; awk -f ./src/parser.awk "$@" )
  }

  It "ignores empty lines"
    data() { %text
      #|
      #|FOO=bar
    }
    When call parse_env "$(data)"
    The output should eq "FOO='bar'"
  End

  It "ignores comment lines"
    data() { %text
      #|# comment
      #|  # comment
      #|FOO=bar
    }
    When call parse_env "$(data)"
    The output should eq "FOO='bar'"
  End

  It "don't accept unknown dialect"
    data() { %text
      #|echo a b c
      #|FOO=value
    }
    When call parse_env "$(data)"
    The status should be failure
    The error should eq "shdotenv: \`echo a b c': not a variable definition"
  End

  It "accepts supported dotenv dialect"
    data() { %text
      #|# dotenv posix
      #|FOO=value
    }
    When call parse_env "$(data)"
    The output should eq "FOO='value'"
    The status should be success
  End

  Context "when the key is given"
    Describe
      Parameters
        '  FOO=bar'                 "FOO='bar'"
        'FOO_BAR=value'             "FOO_BAR='value'"
        'FOO1=value'                "FOO1='value'"
        'export FOO'                "export FOO"
        'export FOO BAR'            "export FOO BAR"
        'export FOO BAR # comment'  "export FOO BAR"
      End

      It "parses value the \`$1'"
        When call parse_env "$1"
        The output should eq "$2"
      End
    End

    Describe
      Parameters
        'FOO'             "shdotenv: \`FOO': not a variable definition"
        'FOO =value'      "shdotenv: \`FOO ': no space allowed after the key"
        'FOO= value'      "shdotenv: \`FOO= value': spaces are not allowed without quoting"
        'FOO==value'      "shdotenv: \`FOO==value': unquoted '=' not allowed for first character"
        'FOO.BAR=value'   "shdotenv: \`FOO.BAR': the key is not a valid identifier"
        '0FOO=value'      "shdotenv: \`0FOO': the key is not a valid identifier"
        'export FOO.BAR'  "shdotenv: \`FOO.BAR': the key is not a valid identifier"
      End

      It "does not parse key the \`$1'"
        When call parse_env "$1"
        The status should be failure
        The error should eq "$2"
      End
    End
  End

  Context "when the unquoted value is given"
    Describe
      Parameters
        'FOO=value'                 "FOO='value'"
        "FOO=#value # comment"      "FOO='#value'"
        "FOO=#value#no-comment"     "FOO='#value#no-comment'"
        "FOO=value   "              "FOO='value'"
        'export FOO=value'          "export FOO='value'"
      End

      It "parses value the \`$1'"
        When call parse_env "$1"
        The output should eq "$2"
      End
    End

    Describe
      Parameters:value "#" "%" "+" "," "-" "." "/" ":" "=" "@" "^" "_" ""
      It "parses value the \`$1'"
        When call parse_env "FOO=v$1"
        The output should eq "FOO='v$1'"
      End
    End

    Describe
      Parameters
        "FOO=foo bar"
        "FOO=   foo"
        "FOO=${HT}foo"
      End

      It "does not parse value the \`$1'"
        When call parse_env "FOO=$1"
        The status should be failure
        The error should eq "shdotenv: \`FOO=$1': spaces are not allowed without quoting"
      End
    End

    Describe
      Parameters:value "!" "\$" "&" "(" ")" "*" ";" "<" ">" "?" "[" "\\" "]" "\`" "{" "|" "}" "~"

      It "does not parse value the \`$1'"
        When call parse_env "FOO=$1"
        The status should be failure
        The error should eq "shdotenv: \`FOO=$1': using without quotes is not allowed: !\$&()*;<>?[\\]\`{|}~"
      End
    End
  End

  Context "when the single quoted value is given"
    Describe
      Parameters
        "FOO='value'"               "FOO='value'"
        "FOO='#value' # comment"    "FOO='#value'"
        "FOO='#value # comment'"    "FOO='#value # comment'"
        "FOO='value'   "            "FOO='value'"
        "FOO=''"                    "FOO=''"
        "export FOO='value'"        "export FOO='value'"
      End

      It "parses value the \`$1'"
        When call parse_env "$1"
        The output should eq "$2"
      End
    End

    It "parses multi-line values"
      data() { %text
        #|export FOO='line 1
        #|line 2
        #|line 3'
      }
      result() { %text
        #|export FOO='line 1
        #|line 2
        #|line 3'
      }
      When call parse_env "$(data)"
      The output should eq "$(result)"
    End

    It "parses multi-line values with comment"
      data() { %text
        #|export FOO='line 1
        #|line 2
        #|line 3'  # comment
      }
      result() { %text
        #|export FOO='line 1
        #|line 2
        #|line 3'
      }
      When call parse_env "$(data)"
      The output should eq "$(result)"
    End

    It "parses multi-line values with invalid comment"
      data() { %text
        #|export FOO='line 1
        #|line 2
        #|line 3'# comment
      }
      result() { %text
        #|`export FOO='line 1
        #|line 2
        #|line 3'# comment': spaces are required before the end-of-line comment
      }
      When call parse_env "$(data)"
      The status should be failure
      The error should eq "shdotenv: $(result)"
    End

    Describe
      Parameters
        "FOO='#value'# comment"   "shdotenv: \`FOO='#value'# comment': spaces are required before the end-of-line comment"
        "FOO='#va'lue'"           "shdotenv: \`FOO='#va'lue'': using single quote not allowed in the single quoted value"
        "FOO='value"              "shdotenv: \`FOO='value': unterminated quoted string"
        "FOO=\"value"             "shdotenv: \`FOO=\"value': unterminated quoted string"
      End

      It "does not parse value the \`$1'"
        When call parse_env "$1"
        The status should be failure
        The error should eq "$2"
      End
    End
  End

  Context "when the double quoted value is given"
    Describe
      Parameters
        'FOO="value"'                 "FOO='value'"
        'FOO="#value" # comment'      "FOO='#value'"
        'FOO="#value # comment"'      "FOO='#value # comment'"
        'FOO="value"   '              "FOO='value'"
        'FOO=""'                      "FOO=''"
        'export FOO="value"'          "export FOO='value'"
        'FOO="escaped\"value"'        "FOO='escaped\"value'"
        'FOO="escaped\$value"'        "FOO='escaped\$value'"
        'FOO="escaped\`value"'        "FOO='escaped\`value'"
        'FOO="escaped\\value"'        "FOO='escaped\\value'"
        'FOO="escaped\nvalue"'        "FOO='escaped\nvalue'"
      End

      It "parses value the \`$1'"
        When call parse_env "$1"
        The output should eq "$2"
      End
    End

    It "parses multi-line values"
      data() { %text
        #|export FOO="line 1
        #|line 2
        #|line 3"
      }
      result() { %text
        #|export FOO='line 1
        #|line 2
        #|line 3'
      }
      When call parse_env "$(data)"
      The output should eq "$(result)"
    End

    It "parses multi-line values with comment"
      data() { %text
        #|export FOO="line 1
        #|line 2
        #|line 3"  # comment
      }
      result() { %text
        #|export FOO='line 1
        #|line 2
        #|line 3'
      }
      When call parse_env "$(data)"
      The output should eq "$(result)"
    End

    It "parses multi-line values with invalid comment"
      data() { %text
        #|export FOO="line 1
        #|line 2
        #|line 3"# comment
      }
      result() { %text
        #|`export FOO="line 1
        #|line 2
        #|line 3"# comment': spaces are required before the end-of-line comment
      }
      When call parse_env "$(data)"
      The status should be failure
      The error should eq "shdotenv: $(result)"
    End

    It "allows a trailing backslash"
      data() { %text
        #|export FOO="line 1\
        #|line 2"  # comment
      }
      result() { %text
        #|export FOO='line 1line 2'
      }
      When call parse_env "$(data)"
      The output should eq "$(result)"
    End

    Describe
      Parameters
        'FOO="#value"# comment' "shdotenv: \`FOO=\"#value\"# comment': spaces are required before the end-of-line comment"
        'FOO="value'            "shdotenv: \`FOO=\"value': unterminated quoted string"
        'FOO="$VAR"'            "shdotenv: \`FOO=\"\$VAR\"': the following metacharacters must be escaped: \$\`\"\\"
        'FOO="${VAR-}"'         "shdotenv: \`FOO=\"\${VAR-}\"': the variable name is not a valid identifier"
        'FOO="${VAR?}"'         "shdotenv: \`FOO=\"\${VAR?}\"': the variable name is not a valid identifier"
        'FOO="val"ue"'          "shdotenv: \`FOO=\"val\"ue\"': the following metacharacters must be escaped: \$\`\"\\"
      End

      It "does not parse value the \`$1'"
        When call parse_env "$1"
        The status should be failure
        The error should eq "$2"
      End
    End
  End
End
