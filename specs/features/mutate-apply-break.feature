@mutate @apply-break
Feature: A break is applied to a file as a substitution, the same way every time

  tests/apply-break.ts takes a file and one substitution, written s, a delimiter, a pattern, the delimiter, a replacement, the delimiter and optional flags. The runner calls it for every break.

  Decision (2026-11-12): The substitution is read as a JavaScript regular expression, and the replacement keeps the escapes the breaks were written with. Why: the kept breaks use plain regular expression features, and these are the escapes they use.
  Decision (2026-11-12): A substitution that is not valid leaves the file as it was and exits with status 2 and a reason. Why: a bad break must never look like a break that applied.

  Scenario: Without a flag only the first match changes
    Given a text file that reads:
      """
      a a a
      """
    When the break "s/a/b/" is applied to the file
    Then the script exits with status 0
    And the file reads:
      """
      b a a
      """

  Scenario: The flag g changes every match
    Given a text file that reads:
      """
      a a a
      """
    When the break "s/a/b/g" is applied to the file
    Then the file reads:
      """
      b b b
      """

  Scenario: The flag i ignores case
    Given a text file that reads:
      """
      Apple
      """
    When the break "s/apple/pear/i" is applied to the file
    Then the file reads:
      """
      pear
      """

  Scenario: The flag m lets ^ match at the start of a line
    Given a text file that reads:
      """
      x
      y
      """
    When the break "s/^y/z/m" is applied to the file
    Then the file reads:
      """
      x
      z
      """

  Scenario: Without the flag m ^ matches only the start of the file
    Given a text file that reads:
      """
      x
      y
      """
    When the break "s/^y/z/" is applied to the file
    Then the file reads:
      """
      x
      y
      """

  Scenario: The flag s lets a dot match a newline, and without it a dot does not
    Given a text file that reads:
      """
      x
      y
      """
    When the break "s/x.y/Z/" is applied to the file
    Then the file reads:
      """
      x
      y
      """
    When the break "s/x.y/Z/s" is applied to the file
    Then the file reads:
      """
      Z
      """

  Scenario: A capture is used in the replacement
    Given a text file that reads:
      """
      ab
      """
    When the break "s/(a)(b)/$2$1/" is applied to the file
    Then the file reads:
      """
      ba
      """

  Scenario: A newline, a tab, a backslash and a dollar sign in the replacement
    Given a text file that reads:
      """
      a,b
      """
    When the break "s/,/\n\t\\\$/" is applied to the file
    Then the file reads:
      """
      a
      	\$b
      """

  Scenario: Another delimiter, and the delimiter written after a backslash
    Given a text file that reads:
      """
      a/b
      """
    When the break "s~a/b~c\~d~" is applied to the file
    Then the file reads:
      """
      c~d
      """

  Scenario: A break that matches nothing leaves the file as it was
    Given a text file that reads:
      """
      a
      """
    When the break "s/zzz/b/" is applied to the file
    Then the script exits with status 0
    And the file reads:
      """
      a
      """

  Scenario: Carriage returns and accented letters come through unchanged
    Given a text file with Windows line endings that reads "caf\u00e9 x" and "end"
    When the break "s/x/y/" is applied to the file
    Then the file holds the bytes of "caf\u00e9 y\r\nend\r\n"

  Scenario Outline: A substitution that is not valid leaves the file as it was
    Given a text file that reads:
      """
      a
      """
    When the break "<substitution>" is applied to the file
    Then the script exits with status 2
    And the output mentions "<reason>"
    And the file reads:
      """
      a
      """

    Examples:
      | substitution | reason                  |
      | a/b/         | not a substitution      |
      | s/a/b        | not terminated          |
      | s/a/b/z      | unknown flag            |
      | s/(/b/       | not a valid pattern     |
      | sxaxbx       | not a substitution      |
      | s/a/b/g/     | unknown flag            |

  Scenario: A file that does not exist is a bad call
    When the break "s/a/b/" is applied to a file that does not exist
    Then the script exits with status 2
    And the output mentions "no such file"
