@skills-text
Feature: The deliver command gives the default out-of-scope file

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): This check is written although it is about deliver.md. Why: the default row text of deliver.md is a contract with the config template. An earlier version named deliver-records, which was dropped in the approach review.

  Scenario: The command gives the default out-of-scope file
    Given the plugin command "deliver"
    Then it contains "No **out_of_scope_file**: use `docs/out-of-scope.md`"
