@examples-guard
Feature: The examples guard checks that generated scenarios still say what their examples say

  A feature can have an examples file beside it, such as `loans.examples.md` next to `loans.feature`. Each example is a line that starts with its id, such as `E2.`. A scenario generated from an example carries the tags `@example-E2`, `@src-<hash>` and `@gen-<hash>`. The script checks the link between the two with no model: the ids, the concrete values and two hashes.

  Decision (2026-11-15): The checks are mechanical and a model judges none of them. Why: the verdict must be repeatable, and a model can generate while a script checks. Agreed with the builder.
  Decision (2026-11-15): A scenario without an example tag is Gherkin-owned and no check touches it. Why: a developer owns a technical scenario, and a project that adopted an earlier version has only such scenarios. Chosen by the builder.
  Decision (2026-11-15): A value is a text in double quotes or a number outside quotes, and each must appear in the scenario. A number is a whole token, so 5 is not found in 50. Why: it catches the worst drift, a changed number, without reading meaning. A value written differently in the two places is an open point of the trial.
  Decision (2026-11-15): The source hash is the first 8 characters of the SHA-256 of the example text after its id, with the spaces collapsed. The generated hash is the same of the scenario from its keyword line to its end, with tags, comments and blank lines left out and the spaces collapsed. Why: a changed meaning changes the hash, and a changed tag, comment or spacing does not. It is the same normal form as the fingerprint of the decision log.
  Decision (2026-11-15): The script lives at the root, like the decision log script, and is not in the plugin folder. Why: the plugin folder holds text only.

  Rule: The examples files are found next to their features

    Scenario: A project with no examples file has nothing to check
      Given a project with the late loan feature and no examples file
      When the examples are checked
      Then the script exits with status 0
      And the output mentions "I-NONE"
      And the output mentions "summary errors=0"

    Scenario: A scenario without an example tag is not touched
      Given a project with the late loan examples and their scenarios
      And the feature file "loans.feature" gets a scenario owned by Gherkin
      When the examples are checked
      Then the script exits with status 0

    Scenario: An examples file in a nested folder is found
      Given a project with the late loan examples and their scenarios in the folder "billing/fees"
      And the text "3 days" is replaced by "4 days" in the examples file "billing/fees/loans.examples.md"
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-SRC"

    Scenario: An examples file with no feature file beside it fails
      Given the examples file "orphans.examples.md" reads:
        """
        E1. A loan returned on time shows a fee of 0.
        """
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-NOFEATURE"
      And the output mentions "orphans.examples.md"

    Scenario: Windows line endings in both files are fine
      Given a project with the late loan examples and their scenarios, with Windows line endings
      When the examples are checked
      Then the script exits with status 0

  Rule: Every example has a scenario and every generated scenario has an example

    Scenario: Examples and scenarios that match pass
      Given a project with the late loan examples and their scenarios
      When the examples are checked
      Then the script exits with status 0
      And the output mentions "summary errors=0"

    Scenario: An example with no scenario fails and names its id
      Given a project with the late loan examples and their scenarios
      And the examples file "loans.examples.md" gets the line "E3. A loan returned 10 days late shows a fee of 12."
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-MISSING"
      And the output mentions "E3"

    Scenario: A generated scenario with no example fails and names its id
      Given a project with the late loan examples and their scenarios
      And the text "@example-E2" is replaced by "@example-E9" in the feature file "loans.feature"
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-ORPHAN"
      And the output mentions "E9"

    Scenario: An id used twice in an examples file fails
      Given a project with the late loan examples and their scenarios
      And the examples file "loans.examples.md" gets the line "E1. A loan returned early shows a fee of 0."
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-DUP"
      And the output mentions "E1"

    Scenario: An id tagged on two scenarios fails and names its id
      Given a project with the late loan examples and their scenarios
      And the text "@spec-on-time @example-E1" is replaced by "@spec-on-time @example-E2" in the feature file "loans.feature"
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-DUP"
      And the output mentions "tagged on more than one scenario"

  Rule: The concrete values of an example appear in its scenario

    Scenario: A quoted text that is not in the scenario fails and names the value
      Given a project with the late loan examples and their scenarios
      And the text "late by 3 days" is replaced by "overdue" in the feature file "loans.feature"
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-VALUE"
      And the output mentions "late by 3 days"

    Scenario: A number that is not in the scenario fails and names the value
      Given a project with the late loan examples and their scenarios
      And the text "a fee of 5" is replaced by "a fee of 6" in the feature file "loans.feature"
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-VALUE"
      And the output mentions "value 5 is missing"

    Scenario: A number found only inside a longer number is not found
      Given a project with the late loan examples and their scenarios
      And the text "a fee of 5" is replaced by "a fee of 50" in the feature file "loans.feature"
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-VALUE"

    Scenario: A decimal number is one value
      Given a project with the late loan examples and their scenarios
      And the text "a fee of 5." is replaced by "a fee of 2.5." in the examples file "loans.examples.md"
      And the text "a fee of 5" is replaced by "a fee of 2.5" in the feature file "loans.feature"
      And the feature file "loans.feature" is stamped
      When the examples are checked
      Then the script exits with status 0

    Scenario: A value in a table of the scenario counts
      Given the examples file "fees.examples.md" reads:
        """
        E1. A loan returned 3 days late has a fee of 5.
        """
      And the feature file "fees.feature" reads:
        """
        Feature: Fees

          @spec-fee @example-E1 @src-? @gen-?
          Scenario: A late loan has a fee
            Given these loans:
              | days late | fee |
              | 3         | 5   |
        """
      And the feature file "fees.feature" is stamped
      When the examples are checked
      Then the script exits with status 0

    Scenario: The id of an example is not a value
      Given the examples file "ids.examples.md" reads:
        """
        E12. A loan returned on time shows no fee.
        """
      And the feature file "ids.feature" reads:
        """
        Feature: Ids

          @spec-no-fee @example-E12 @src-? @gen-?
          Scenario: An on time loan shows no fee
            Given a loan returned on time
            Then no fee is shown
        """
      And the feature file "ids.feature" is stamped
      When the examples are checked
      Then the script exits with status 0

  Rule: A changed example fails on the source hash

    Scenario: An example changed after its scenario was generated fails and names its id
      Given a project with the late loan examples and their scenarios
      And the text "returned on 4 Nov" is replaced by "returned on 5 Nov" in the examples file "loans.examples.md"
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-SRC"
      And the output mentions "E2"
      And the output does not mention "E1"

    Scenario: Spacing in an example does not change the hash
      Given a project with the late loan examples and their scenarios
      And the text "E2. A loan due" is replaced by "E2.    A  loan   due" in the examples file "loans.examples.md"
      When the examples are checked
      Then the script exits with status 0

    Scenario: A generated scenario with no source hash fails
      Given a project with the late loan examples and their scenarios
      And the text " @src-" is replaced by " @nosrc-" in the feature file "loans.feature"
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-NOHASH"

  Rule: A hand edit of a generated scenario fails on the generated hash

    Scenario: A reworded step fails and names the id
      Given a project with the late loan examples and their scenarios
      And the text "When it is returned on" is replaced by "When the borrower brings it back on" in the feature file "loans.feature"
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-GEN"

    Scenario: A changed tag or spacing does not fail
      Given a project with the late loan examples and their scenarios
      And the text "@spec-late-label" is replaced by "@spec-late-label @pending" in the feature file "loans.feature"
      And the text "Given a loan due on" is replaced by "Given   a  loan due on" in the feature file "loans.feature"
      When the examples are checked
      Then the script exits with status 0

    Scenario: A generated scenario with no generated hash fails
      Given a project with the late loan examples and their scenarios
      And the text " @gen-" is replaced by " @nogen-" in the feature file "loans.feature"
      When the examples are checked
      Then the script exits with status 1
      And the output mentions "E-NOHASH"

  Rule: The hashes can be asked for

    Scenario: The source hash is the first 8 characters of the SHA-256 of the example text
      Given a project with the late loan examples and their scenarios
      When the source hash of "E1" is asked for in the examples file "loans.examples.md"
      Then the script exits with status 0
      And the output is the first 8 characters of the SHA-256 of "A loan due on 1 Nov and returned on 1 Nov shows no late label and a fee of 0."

    Scenario: The generated hash is the first 8 characters of the SHA-256 of the scenario text
      Given the feature file "plain.feature" reads:
        """
        Feature: Plain

          @spec-plain @example-E1
          # a note
          Scenario:   A plain   scenario
            Given a thing

            # a comment inside the scenario
            Then it   works
        """
      When the scenario hash of "E1" is asked for in the feature file "plain.feature"
      Then the output is the first 8 characters of the SHA-256 of the lines "Scenario: A plain scenario", "Given a thing" and "Then it works"

    Scenario: Windows line endings do not change the source hash
      Given a project with the late loan examples and their scenarios
      And the source hash of "E2" in the examples file "loans.examples.md" is remembered
      And the examples file "loans.examples.md" is rewritten with Windows line endings
      When the source hash of "E2" is asked for in the examples file "loans.examples.md"
      Then the output is the remembered hash

    Scenario: Windows line endings do not change the generated hash
      Given a project with the late loan examples and their scenarios
      And the scenario hash of "E2" in the feature file "loans.feature" is remembered
      And the feature file "loans.feature" is rewritten with Windows line endings
      When the scenario hash of "E2" is asked for in the feature file "loans.feature"
      Then the output is the remembered hash

    Scenario: An id that is not found is reported
      Given a project with the late loan examples and their scenarios
      When the source hash of "E7" is asked for in the examples file "loans.examples.md"
      Then the script exits with status 1
      And the output mentions "E7"

  Rule: The script needs a features folder

    Scenario: A missing features folder is a usage error
      Given a project with no scenarios
      When the examples are checked in the folder "nowhere"
      Then the script exits with status 2
      And the output mentions "features directory not found"
