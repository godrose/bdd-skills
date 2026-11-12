@skills-text
Feature: The deliver command gives the default out-of-scope file

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): This check is written although it is about deliver.md. Why: deliver-records holds only the row name, and an earlier exclusion says this check stays with test_skills.sh.

  Scenario: The command gives the default out-of-scope file
    Given the plugin command "deliver"
    Then it contains "No **out_of_scope_file**: use `docs/out-of-scope.md`"
