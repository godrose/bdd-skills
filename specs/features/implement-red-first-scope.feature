@red-first
Feature: The red-first check lives in implement only

  Decision (2026-11-11): The check of the other command files does not cover deliver.md, which also says red-first. Why: the old test did not check it, and a migration adds no checks.

  Scenario Outline: <file> does not mention the red-first check
    Given the file "<file>"
    Then it does not mention "red-first" in any letter case

    Examples:
      | file                        |
      | plugin/commands/run.md      |
      | plugin/agents/verifier.md   |
      | plugin/commands/design.md   |
      | plugin/commands/discover.md |

  Scenario: The config template has no row for the red-first check
    Given the file "plugin/bdd-config.template.md"
    Then it does not mention "red_first" in any letter case
