@skills-text
Feature: A missing config file stops the run command and the verifier agent

  These scenarios read the text of the command and of the agent. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): Only run and verifier are written here. Why: deliver is in deliver-shape, and design, implement, triage and reconcile come in the next pull requests.

  Scenario Outline: The <file> text says to stop when the config does not exist and names the template
    Given the file "<file>"
    Then it contains:
      | does not exist, say so and stop |
      | `bdd-config.template.md`        |

    Examples:
      | file                      |
      | plugin/commands/run.md    |
      | plugin/agents/verifier.md |
