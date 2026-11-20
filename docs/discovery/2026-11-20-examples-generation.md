# Discovery: design generates scenarios from the examples file

## Story

Slice 2 of `2026-11-15-examples-source.md`. Slice 1 gave the examples file its shape and a guard script, `scripts/examples.sh`. This slice makes the plugin use them: `discover` writes the examples file, `design` generates the scenarios from it and stamps the two hashes, the config row `spec_source` chooses the flow, and the guard script reaches the project.

## Existing behavior

- `discover` writes a pack with agreed examples (E1, E2 and so on). It writes no file in the features folder.
- `design` drafts Gherkin from a story or a pack, audits the reuse of steps, shows the scenarios and waits for the go-ahead.
- The plugin folder holds no scripts: the directory refuses a file that starts with `#!` from an organization that is not verified. The decision log has the same gap. In a plugin install, `design` says "The decision log needs the project install of this repository" and records nothing. Only the project-file install copies a script, and the README says it stays for a few releases.
- `/bdd:init` creates `.claude/bdd-config.md` from the template and can propose values. It downloads nothing.

## Agreed examples

| # | Situation | What happens |
|---|-----------|--------------|
| G1 | `/bdd:init` runs in a fresh project | It asks one question: add the examples guard script to the project. On yes it downloads `scripts/examples.sh` from this repo at the tag pinned in the plugin text, checks its SHA-256 against the one pinned with it, writes it to the path in the `examples_guard` row, sets `spec_source` to `examples` and says to commit the script. |
| G2 | The download fails, or the checksum does not match | Nothing is written. It says which one, in one line, and leaves `spec_source` as it is, so the next run offers the script again (decision 11). |
| G3 | The user says no | Nothing is downloaded. `spec_source` is set to `gherkin`. |
| G4 | `discover` ends with agreed examples, `spec_source` is `examples` and the script is there | Its Agreed examples are labelled examples, one per line (`E1. ` and the example). It writes no file. `design` writes `<features_dir>/<slug>.examples.md` from them after the one approval (G6). |
| G5 | `design` runs on a story that has an examples file | It writes `<features_dir>/<slug>.feature`, a file of its own, with a comment at the top that says it is generated and to change the examples instead. Each scenario carries the spec id tag, `@example-En`, and the `@src-` and `@gen-` hashes from the script. Existing steps are reused first. There is no second approval. It runs `examples.sh check` and shows the result under "For the developer:". |
| G6 | `design` runs directly on a story with no examples file | It drafts the examples, asks for the one approval of them, writes the examples file, then goes on as in G5. The same path whoever runs it. |
| G7 | Generation finds something that changes what a scenario proves | One plain question about the behavior, asked alone (E9 of the examples-source pack). The answer goes into the example, and the scenario is generated again. |
| G8 | An example changed after its scenario was generated | `design` generates only that scenario again and stamps both hashes again. The other scenarios are left as they are. |
| G9 | `spec_source` is `examples` and the script is not there | One line: the examples flow needs the guard script, run `/bdd:init` to add it, and this run uses Gherkin. Then the run goes on as today. |
| G10 | `spec_source` is `gherkin`, or the row is absent and no script is there | The plugin works as it does today. |
| G11 | The project-file install runs | `install.sh` copies `scripts/examples.sh` to `.claude/scripts/examples.sh`, as it does `decisions.sh`. |
| G12 | Anyone runs `design` or `deliver` in examples mode | What is approved is the examples. The generated scenarios appear only under "For the developer:", and anyone can ask to see the scenario of an example. |

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | `/bdd:init` gets the guard script into the project: it asks first, downloads it at the plugin's version tag and checks a SHA-256 written in the plugin text. Chosen by the builder (option 2 of three). | One guard everywhere: `design`, CI and the app run the same file, and the checksum pins it. The project owns a committed copy. The alternatives tied the flow to the install that is being retired, or wrote the normal form twice. |
| 2 | When the script is declined or missing, the flow falls back to Gherkin and says so in one line. Chosen by the builder, with option 2. | The same as the decision log's missing script. A run is never blocked by a missing file. |
| 3 | `spec_source` defaults to `examples` only when the script is in the project. `init` writes the row. My call. | A default that cannot work is a wrong default. |
| 4 | The flow does not depend on who runs the command. The examples are approved, and the generated scenarios are under "For the developer:". Chosen by the builder. | One source of truth for a story, whoever starts it. This replaces the idea of showing a developer the Gherkin at the approval. |
| 5 | Generated scenarios go into a feature file of their own, one per examples file. A hand-written feature file is never written to. My call. | "Generated" is a property of a whole file, and the guard already pairs one examples file with one feature file. There are no users yet (the builder), so no mixed file needs a migration. |
| 6 | The checksum in the plugin text is changed by the release PR that changes the script, and a test checks that it matches `scripts/examples.sh`. My call. | A wrong checksum would refuse every download. A test finds it before a release. |
| 7 | `install.sh` copies `scripts/examples.sh` like `decisions.sh`. My call. | The project-file install stays for a few releases, and it should not lack the guard. |
| 8 | The script's path is the `examples_guard` row, `scripts/bdd/examples.sh` by default. The project-file install rewrites it to `.claude/scripts/examples.sh` and copies the script there. My call. | The plugin text may not name the project install's script folder, and a test checks it. A project path also suits CI. |
| 9 | `design` writes the examples file, and `discover` writes nothing. Replaces E1 of the examples-source pack and G4 as first written, which had `discover` write it. My call. | `discover` changes nothing but its pack folder, which a flow harness rule checks. `design` already has the approval and writes files, and `deliver` calls it. |
| 10 | The guard script has a pin of its own in `init`: a tag and the SHA-256 of the script at that tag. A test checks the pin against the script at the tag, or against `scripts/examples.sh` while the tag does not exist yet. The release check fails unless the pin is the released script, at a tag that holds it or at the new version's tag. Replaces decision 1's download at the plugin's version tag, and decision 6. Found in the review of the PR. My call, approved by the builder. | At the plugin's version tag the script did not exist before a release. After one, a feature PR that changed the script had to change the checksum, and `main` then checked the new checksum against the old tag's script, so every fresh install failed until the next release. |
| 11 | A failed download or a wrong checksum leaves `spec_source` as it is. Only a no sets `gherkin`. Replaces G2 as first written. Found in the review of the PR. | A network failure is not a choice. With `gherkin` written, `init` would never offer the script again. |

## Existing users

None yet, in the builder's words. A project with hand-written `.feature` files keeps them: they have no example id, so they are Gherkin-owned and no guard touches them, and `design` never writes into them (decision 5). The row `spec_source` is absent there, and with no script the plugin works as today (G10).

## First run

`/bdd:init` asks about the script (G1). On yes, the first `discover` ends with the examples file and one approval, and `design` generates the feature file without showing it. On no, everything is as today.

## Exclusions

- No guard in a plugin install without the download. The plugin folder holds no scripts.
- No Windows without bash. The script is bash, like `decisions.sh`.
- No migration of hand-written scenarios into examples, and no generated scenario in a hand-written file.
- No change to `implement`: it reads the generated scenarios like any other.
- No change to `deliver` in this slice. Its one approval and the report by example id are slice 3.
- No fix for the decision log's missing script, though the same download could serve it later.

## Open, for the spec

- The checksum scenario fails on every change of the script, so a mutation run of the script must keep its tag filter. The break file says so.

- The download source at a tag only exists after a release, and this branch is not released. The spec needs a source that tests can point at a local copy, and a real download is tried once by hand.
- Downloading needs the network and runs a Bash command the user approves. The question in G1 has to say so plainly.
