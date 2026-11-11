@plugin-text
Feature: The README warns about headless runs and no text file has an em-dash

  These scenarios read files and text. They check what the files say and run nothing. The second one scans the repo.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): The scan skips .git, docs, results, node_modules, lib.sh and test_lib.sh. Why: the old scan did, and the old test files hold the dash on purpose. The test_plugin.sh and test_readme.sh exclusions drop out with those files.
  Decision (2026-11-11): The em-dash checks of discover.md, reconcile.md and triage.md in test_skills.sh are covered by this scan and skip later. Why: written once.

  Scenario: The README says a headless run may need the write approved by hand
    Given the README
    Then it contains:
      | claude -p         |
      | approve the write |

  Scenario: No text file outside docs has an em-dash
    Given the text files of the repo outside docs
    Then none of them has an em-dash
