@examples-generation
Feature: The plugin generates scenarios from the examples file

  These scenarios read the plugin text, check the checksum against the script, and run the project-file install.
  The discovery pack is docs/discovery/2026-11-20-examples-generation.md.

  Decision (2026-11-20): init gets the guard script into the project: it asks first, downloads it and checks a SHA-256 written in its text. Why: the plugin folder holds no scripts, and one checked copy serves design, CI and the app. Chosen by the builder.
  Decision (2026-11-20): Declined or missing, the flow falls back to Gherkin and says so in one line. Why: a run is never blocked by a missing file, as with the decision log. Chosen by the builder.
  Decision (2026-11-20): The flow is the same whoever runs it: the examples are approved, and the generated scenarios are under "For the developer:". Why: one source of truth for a story. Chosen by the builder.
  Decision (2026-11-20): The script's path is the examples_guard row, a project path, and the project-file install rewrites it to its own folder. Why: the plugin text may not name the project install's script folder.
  Decision (2026-11-20): design writes the examples file, and discover writes nothing. Why: discover changes nothing but its pack folder, and design already has the approval. Replaces E1 of the examples-source pack and G4 of the examples-generation pack, which had discover write it.
  Decision (2026-11-21): The guard script has a pin of its own in init, a tag and a SHA-256, and only a release moves it. Why: the plugin's version tag had no script before a release, and a feature PR that changed the script broke every fresh install until the next release. Replaces the download at the plugin's version tag.
  Decision (2026-11-21): A failed download leaves spec_source as it is, and only a no sets gherkin. Why: a network failure is not a choice, so the next run offers the script again.

  Rule: The config names the flow and the script

    Scenario: The template has an empty spec_source row that names both flows
      Given the file "plugin/bdd-config.template.md"
      Then it contains "| spec_source | `` ("
      And it contains "`examples` or `gherkin`"

    Scenario: The template names a project path for the guard script
      Given the file "plugin/bdd-config.template.md"
      Then it contains "| examples_guard | `scripts/bdd/examples.sh`"

  Rule: init adds the guard script only when the user says yes

    Scenario: init asks before it downloads, and says what the download is
      Given the plugin command "init"
      Then it contains:
        | ### Examples guard                                |
        | Add the examples guard script to this project?    |
        | downloads one bash script from github.com/godrose/bdd-skills |

    Scenario: init downloads the script at the tag it pins, not at the plugin's version
      Given the plugin command "init"
      Then it contains:
        | https://raw.githubusercontent.com/godrose/bdd-skills/<tag>/scripts/examples.sh |
        | The guard script is pinned to tag `v                                            |
      And it does not contain ".claude-plugin/plugin.json"

    Scenario: init checks the checksum before the script takes its place
      Given the plugin command "init"
      Then it mentions these in this order:
        | Its SHA-256 at that tag is                     |
        | .claude/examples-guard.part                    |
        | Only when the checksum matches, move it into place |
        | mv .claude/examples-guard.part                 |

    Scenario: The pinned checksum is the SHA-256 of the script at the pinned tag, or of the script here before that tag is released
      Given the plugin command "init"
      Then its guard pin matches the script at the pinned tag, or scripts/examples.sh while that tag does not exist

    Scenario: A failed download or a wrong checksum writes nothing, and the next run offers the script again
      Given the plugin command "init"
      Then it contains:
        | the download failed or the checksum did not match |
        | Nothing is written.                                |
        | Leave `spec_source` as it is                       |
        | the next run offers the script again               |

    Scenario: A no downloads nothing
      Given the plugin command "init"
      Then it contains "On no, download nothing and set `spec_source` to `gherkin`."

    Scenario: init can take a local copy of the script for a trial
      Given the plugin command "init"
      Then it contains "a local copy of the script"

    Scenario: init without --detect still offers the script when the config exists
      Given the plugin command "init"
      Then it contains "Without `--detect`, go on to Examples guard."
      And it does not contain "Without `--detect`, stop here."

    Scenario: init works on a config that has neither new row
      Given the plugin command "init"
      Then it contains:
        | A config with no **examples_guard** row uses `scripts/bdd/examples.sh`. |
        | When the config has no **spec_source** row, add it                      |

    Scenario: The download is the one exception to reading files only
      Given the plugin command "init"
      Then it contains "Read files only, except the download in Examples guard."

  Rule: design generates from the examples file

    Scenario: design reads the flow and the script from the config
      Given the plugin command "design"
      Then it contains:
        | ### Spec source |
        | spec_source     |
        | examples_guard  |

    Scenario: design writes the examples file after one approval of the examples
      Given the plugin command "design"
      Then it contains:
        | <features_dir>/<slug>.examples.md |
        | the one approval of the examples  |

    Scenario: Generated scenarios get a feature file of their own with a header that says so
      Given the plugin command "design"
      Then it contains:
        | <features_dir>/<slug>.feature            |
        | # Generated from <slug>.examples.md. Change the examples, not this file. |

    Scenario: design never writes a generated scenario into a hand-written feature file
      Given the plugin command "design"
      Then it contains "Never write a generated scenario into a feature file that has a scenario without an example id."

    Scenario: design stamps both hashes with the guard script and then runs its check
      Given the plugin command "design"
      Then it mentions these in this order:
        | @example-E<n> |
        | source-hash   |
        | check --features |
      And it contains "scenario-hash"

    Scenario: There is no second approval, and the scenarios are under the developer line
      Given the plugin command "design"
      Then it contains:
        | There is no second approval.                          |
        | Show the generated scenarios only under "For the developer:" |

    Scenario: A changed example regenerates only its own scenario
      Given the plugin command "design"
      Then it contains "generate only that scenario again and stamp both hashes again"

    Scenario: Without the guard script the run uses Gherkin and says so
      Given the plugin command "design"
      Then it contains "The examples flow needs the guard script. Run /bdd:init to add it. This run uses Gherkin."

    Scenario: The flow is the same whoever runs design
      Given the plugin command "design"
      Then it contains "The same path whoever runs it"

    Scenario: design works on a config that has no examples_guard row
      Given the plugin command "design"
      Then it contains "A config with no **examples_guard** row uses `scripts/bdd/examples.sh`."

    Scenario: A deliver checklist needs no second go-ahead in the examples flow
      Given the plugin command "design"
      Then it contains "In the Gherkin flow, still show the scenarios in plain words and wait for the go-ahead."
      And it does not contain "so do not ask for it again. Still show the scenarios"

  Rule: discover writes nothing for the examples

    Scenario: discover writes its agreed examples as labelled examples for design
      Given the plugin command "discover"
      Then it contains:
        | labelled examples                            |
        | `bdd:design` writes the examples file        |

  Rule: The project-file install copies the guard script

    @install
    Scenario: A fresh install adds a guard script that can be run
      Given a project with no .claude folder
      When the installer is run on it
      Then the file "scripts/examples.sh" can be run

    @install
    Scenario: An older config hears about the two new rows
      Given a project whose config reads:
        """
        | features_dir | specs |
        """
      When the installer is run on it
      Then the output mentions:
        | bdd-config.md has no 'spec_source' row    |
        | bdd-config.md has no 'examples_guard' row |

    @install
    Scenario: The installed config points at the installed guard script
      Given a project with no .claude folder
      When the installer is run on it
      Then the installed file "bdd-config.md" contains "| examples_guard | `.claude/scripts/examples.sh`"

  Rule: Only a release moves the guard pin

    Scenario: A release that keeps the script and its pin passes the guard pin check
      Given a main at version "0.8.0" whose init pins the guard script to the released tag "v0.8.0"
      And a release branch that sets the version to "0.8.1"
      When the "guard pin" check is run
      Then the run passes

    Scenario: A release that changes the script without moving the pin fails the guard pin check
      Given a main at version "0.8.0" whose init pins the guard script to the released tag "v0.8.0"
      And a release branch that changes the guard script and sets the version to "0.8.1"
      When the "guard pin" check is run
      Then the run fails

    Scenario: A release that changes the script and pins its own new tag passes the guard pin check
      Given a main at version "0.8.0" whose init pins the guard script to the released tag "v0.8.0"
      And a release branch that changes the guard script, pins it to tag "v0.8.1" and sets the version to "0.8.1"
      When the "guard pin" check is run
      Then the run passes

    Scenario: A pin to a tag that is neither released nor the new version fails the guard pin check
      Given a main at version "0.8.0" whose init pins the guard script to the released tag "v0.8.0"
      And a release branch that changes the guard script, pins it to tag "v0.9.0" and sets the version to "0.8.1"
      When the "guard pin" check is run
      Then the run fails

    Scenario: A plugin with no guard pin passes the guard pin check
      Given a main where the plugin has version "0.7.2"
      And a release branch that sets the version to "0.8.0"
      When the "guard pin" check is run
      Then the run passes
