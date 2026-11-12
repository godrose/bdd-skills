@skills-text
Feature: The discover command has the hooks that the deliver command reads

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The git log check is not written. Why: deliver-records already checks it for discover.

  Scenario: The command names the out-of-scope file, the agreed examples and the first example id
    Given the plugin command "discover"
    Then it contains:
      | out_of_scope_file |
      | Agreed examples   |
      | E1                |

  Scenario: The command gives the default out-of-scope file
    Given the plugin command "discover"
    Then it contains "No **out_of_scope_file**: use `docs/out-of-scope.md`"
