@plugin-text
Feature: The init command hints at the generate setting and asks about the decision log

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.

  Scenario: Detect hints at the generate setting and asks about the decision log
    Given the plugin command "init"
    Then it contains:
      | ### Hints                                        |
      | playwright-bdd                                   |
      | missingSteps                                     |
      | fail-on-run                                      |
      | Never edit project code                          |
      | only when the setting is absent                  |
      | no decision files                                |
      | Turn the decision log on?                        |
      | The one exception to never changing a filled row |
      | only with approval                               |
      | Do not remember a refusal                        |

  Scenario: Without the decision log script, init says so and skips the second note
    Given the plugin command "init"
    Then it contains:
      | the decision log script is not part of the plugin |
      | skip the second note below                        |
