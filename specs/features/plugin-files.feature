@plugin-text
Feature: The files a plugin needs exist, and the old source folders are gone

  These scenarios read files and text. They check what the files say and run nothing. Three check file names or file modes, not text.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): deliver.md, the manifests and the config template are not listed again. Why: deliver-shape.feature and layout-manifests-and-folders.feature already check that they exist.

  Scenario: Every command exists
    Given the repository
    Then the repo has these files:
      | plugin/commands/discover.md  |
      | plugin/commands/design.md    |
      | plugin/commands/implement.md |
      | plugin/commands/run.md       |
      | plugin/commands/triage.md    |
      | plugin/commands/reconcile.md |
      | plugin/commands/init.md      |

  Scenario: The verifier agent exists and is named verifier
    Given the repository
    Then the repo has these files:
      | plugin/agents/verifier.md |
    Given the file "plugin/agents/verifier.md"
    Then it contains "name: verifier"

  Scenario: The decision schema exists
    Given the repository
    Then the repo has these files:
      | schemas/decision.schema.json |

  Scenario: The decisions script can be run
    Given the repository
    Then the repo file "scripts/decisions.sh" can be run

  Scenario: No command or agent has a bdd- file name
    Given the commands and agents of the plugin
    Then none of them has a file name starting with "bdd-"

  Scenario: The old source folders are gone
    Given the repository
    Then the repo has none of these paths:
      | .claude/commands |
      | .claude/agents   |

  Scenario: Shell scripts keep Unix line endings
    Given the file ".gitattributes"
    Then it contains "*.sh text eol=lf"
