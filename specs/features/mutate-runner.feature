@mutate
Feature: The mutation runner breaks a copy of the project and says which breaks the tests miss

  tests/mutate.sh takes a file of breaks, applies each one to a copy of the project, runs the test command and reports CAUGHT or SURVIVED. These scenarios run it on a small sandbox project with its own test command. They never run it on this repo.

  Decision (2026-11-12): The runner only ever breaks copies. Why: an earlier ad hoc run was left alive and kept breaking the real checkout while other tests ran.
  Decision (2026-11-12): The tests must pass before the first break, or the run stops with status 2. Why: a test run that fails for another reason, such as a step that is not defined, would report every break as caught.
  Decision (2026-11-12): A break that changes nothing is reported and fails the run. Why: a break that does not apply says nothing about the tests, and a stale break file would look green.
  Decision (2026-11-12): A survivor marked "equivalent" is expected, and an equivalent mark on a break that is caught fails the run. Why: no input can tell an equivalent change from the real code, and a stale mark hides a test that now does tell them apart.
  Decision (2026-11-12): The runner is by hand and not in CI. Why: it runs the whole suite once for each break.

  Scenario: A break the tests notice is caught
    Given a sandbox project whose test passes while code.txt holds GOOD
    And the breaks file holds:
      | name   | file     | substitution | mark |
      | spoils | code.txt | s/GOOD/BAD/  |      |
    When the mutation runner is run
    Then the script exits with status 0
    And the output mentions "CAUGHT    spoils"

  Scenario: A break the tests miss is a survivor and fails the run
    Given a sandbox project whose test passes while code.txt holds GOOD
    And the breaks file holds:
      | name    | file     | substitution       | mark |
      | harmless | code.txt | s/GOOD/GOOD GOOD/ |      |
    When the mutation runner is run
    Then the script exits with status 1
    And the output mentions "SURVIVED  harmless"

  Scenario: A survivor marked equivalent is expected
    Given a sandbox project whose test passes while code.txt holds GOOD
    And the breaks file holds:
      | name | file     | substitution      | mark       |
      | same | code.txt | s/GOOD/GOOD GOOD/ | equivalent |
    When the mutation runner is run
    Then the script exits with status 0
    And the output mentions "(equivalent, expected)"

  Scenario: An equivalent mark on a break that is caught fails the run
    Given a sandbox project whose test passes while code.txt holds GOOD
    And the breaks file holds:
      | name  | file     | substitution | mark       |
      | stale | code.txt | s/GOOD/BAD/  | equivalent |
    When the mutation runner is run
    Then the script exits with status 1
    And the output mentions "remove the mark"

  Scenario: A break that changes nothing fails the run
    Given a sandbox project whose test passes while code.txt holds GOOD
    And the breaks file holds:
      | name   | file     | substitution | mark |
      | misses | code.txt | s/XX/YY/     |      |
    When the mutation runner is run
    Then the script exits with status 1
    And the output mentions "NOCHANGE  misses"

  Scenario: A break that names a file that does not exist fails the run
    Given a sandbox project whose test passes while code.txt holds GOOD
    And the breaks file holds:
      | name    | file     | substitution | mark |
      | nowhere | none.txt | s/GOOD/BAD/  |      |
    When the mutation runner is run
    Then the script exits with status 1
    And the output mentions "NOFILE    nowhere"

  Scenario: Each break starts from the code as it was
    Given a sandbox project whose test passes while code.txt holds GOOD
    And the breaks file holds:
      | name   | file     | substitution | mark |
      | first  | code.txt | s/GOOD/BAD/  |      |
      | second | code.txt | s/GOOD/BAD/  |      |
    When the mutation runner is run
    Then the output mentions "CAUGHT    first"
    And the output mentions "CAUGHT    second"

  Scenario: The project that is broken is not changed
    Given a sandbox project whose test passes while code.txt holds GOOD
    And the breaks file holds:
      | name   | file     | substitution | mark |
      | spoils | code.txt | s/GOOD/BAD/  |      |
    When the mutation runner is run
    Then the sandbox file "code.txt" still reads "GOOD"
    And the sandbox project is as it was before the run

  Scenario: Tests that fail before any break stop the run
    Given a sandbox project whose test always fails
    And the breaks file holds:
      | name   | file     | substitution | mark |
      | spoils | code.txt | s/GOOD/BAD/  |      |
    When the mutation runner is run
    Then the script exits with status 2
    And the output mentions "fail before any break"
    And the output does not mention "CAUGHT"

  Scenario: Comments and blank lines in the breaks file are ignored
    Given a sandbox project whose test passes while code.txt holds GOOD
    And the breaks file also has a comment line and a blank line before its breaks
    And the breaks file holds:
      | name   | file     | substitution | mark |
      | spoils | code.txt | s/GOOD/BAD/  |      |
    When the mutation runner is run
    Then the script exits with status 0
    And the output mentions "caught: 1"

  Scenario: Several jobs give the lines in the order of the file
    Given a sandbox project whose test passes while code.txt holds GOOD
    And the breaks file holds:
      | name  | file     | substitution      | mark |
      | one   | code.txt | s/GOOD/BAD/       |      |
      | two   | code.txt | s/GOOD/GOOD GOOD/ |      |
      | three | code.txt | s/GOOD/BAD/       |      |
    When the mutation runner is run with 2 jobs
    Then the output lists "CAUGHT    one" before "SURVIVED  two"
    And the output lists "SURVIVED  two" before "CAUGHT    three"
    And the output mentions "caught: 2, survived as expected: 0, to look at: 1"

  Scenario: A breaks file that does not exist is a bad call
    Given a sandbox project whose test passes while code.txt holds GOOD
    When the mutation runner is run on a breaks file that does not exist
    Then the script exits with status 2
    And the output mentions "no such breaks file"

  Scenario Outline: The breaks kept for <area> are well formed and still change the code they name
    Then every line in "tests/mutations/<area>.tsv" has a name, a file and a substitution
    And every break in "tests/mutations/<area>.tsv" changes the file it names

    Examples:
      | area    |
      | flows   |
      | evals   |
      | install |
      | mutate  |
