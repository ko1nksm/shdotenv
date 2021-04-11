# .env syntax dialects

| name   | SAK | EP  | EO  | UQV | SQV | DQV | BE  | ML  | CL  | VE  | DV  | CS  | CMT |
| ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| posix  | 0   | 0   | 0   | 0   | 0   | 0   | 0   | 0   | 0   | 0   | 0   | 0   | 0   |
| docker | 0   | -   | -   | 1   | -   | -   | 0   | -   | -   | -   | 0   | 0   | -   |
| ruby   | 1   | 0   | 1   | 2   | 1   | 1   | 1   | 0   | -   | 1   | 0   | 1   | 1   |
| node   | 1   | -   | 4   | 3   | 1   | 2   | 2   | -   | -   | 2   | 0   | 0   | -   |
| python | 1   | 0   | 2   | 2   | 2   | 3   | 3   | 0   | -   | 3   | 1   | 0   | 2   |
| php    | 1   | 0   | 3   | 2   | 1   | 4   | 4   | 1   | -   | 4   | 0   | 0   | 1   |
| go     | 1   | 0   | 4   | 2   | 1   | 1   | 1   | -   | -   | 5   | 0   | 0   | 1   |

The `posix` is a subset of the POSIX shell syntax.

- SAK: Spaces around the key
  - 0: Remove spaces before the key, spaces after the key are not allowed
  - 1: Remove spaces before and after the key
- EP: Export prefix
  - 0: Allowed
  - -: Not allowed
- EO: Export only
  - 0: Allowed
  - 1: Allowed, but must be set to a value
  - 2: Allowed, but treated as None
  - 3: Allowed, but treated as unset?
  - -: Not allowed
- UQV: Unquoted value (Variable expansion is performed)
  - 0: Spaces and Metacharacters are not allowed
  - 1: Leave spaces as it is (Single and double quote values are not supported)
  - 2: Remove spaces around it
  - 3: Remove spaces around it, but leave comments as is
- SQV: Single quoted value
  - 0: Single quotes cannot be used in it
  - 1: Single quotes can be used in it
  - 2: Single quotes can be used in it, but need to be escaped
- DQV: Double quoted value
  - 0: Need to escape when used within it: \" \` \\ \$
  - 1: Need to escape when used within it: \\
  - 2: Need to escape when used within it: \$
  - 3: Need to escape when used within it: \"
  - 4: Need to escape when used within it: \" \\
- BE: Backslash escape (Double quoted value only)
  - 0: None
  - 1: `\n`, `\r` (Backslashes of other characters will disappear)
  - 2: `\n` (Backslashes of other characters will remain)
  - 3: `\a`,`\b`, `\f`, `\n`, `\r`, `\t`, `\v` (Backslashes of other characters will remain)
  - 4: `\f`, `\n`, `\r`, `\t`, `\v` (Backslashes of other characters will cause an error)
- ML: Multiline within quotes
  - 0: Allowed (single and double quotes)
  - 1: Allowed (double quotes only)
  - -: Not allowed
- CL: Continuation line with backslash
  - 0: Double quoted value only
  - -: Not allowed
- VE: Variable expansion
  - 0: Brace only (`${VAR}`), double quotes
  - 1: Brace and bare (`${VAR}`, `$VAR`), single and double quotes
  - 2: Brace and bare (`${VAR}`, `$VAR`), unquotes and single and double quotes
  - 3: Brace only (`${VAR}`), unquotes and single and double quotes
  - 4: Brace only (`${VAR}`), unquotes and double quotes
  - 5: Brace and bare (`${VAR}`, `$VAR`), unquotes and double quotes
  - -: Not allowed
- DV: Default value (`${VAR-default}`, `${VAR:-default}`)
  - 0: Not allowed
  - 1: Allowed (`${VAR:-default}` only)
- CS: Command Substitution
  - 0: Not allowed
  - 1: Allowed
- CMT: Comments at end of line
  - 0: Allowed and requires spaces before `#`
  - 1: Allowed and no requires spaces before `#`
  - 2: Allowed and no requires spaces before `#` except unquoted value
  - -: Not allowed
