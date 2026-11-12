# Out of scope

2026-11-11 | excluded: failing a feature PR that changes the plugin and keeps the version | why: feature PRs never bump the version, only release PRs do | revisit when: the policy changes
2026-11-11 | excluded: checks on the changelog entry and on the marketplace version in the release scenarios | why: other checks cover them, outside this change
2026-11-11 | excluded: new install checks beyond tests/test_install.sh (other commands protected from overwrite, the legacy-file cleanup, the version in the source line) | why: a migration adds no checks | revisit when: the migration series is done
2026-11-11 | excluded: the "lib.sh sets PLUGIN" check from tests/test_layout.sh | why: it tests the bash helper, not the repo layout, and the library is deleted at the end of the series | revisit when: never, tests/test_lib.sh covers the library
2026-11-11 | excluded: new layout checks beyond tests/test_layout.sh (for example untracked files in plugin/, unquoted tool lists) | why: a migration adds no checks | revisit when: the migration series is done
2026-11-11 | excluded: new decision log checks beyond tests/test_decisions.sh | why: a migration adds no checks | revisit when: the migration series is done
2026-11-11 | excluded: new README checks beyond tests/test_readme.sh (external links, badges resolving) | why: a migration adds no checks | revisit when: the migration series is done
2026-11-11 | excluded: the bash file's own helpers and exit-code counting as scenarios | why: they test the harness, not the script | revisit when: never
2026-11-11 | excluded: exact message wording beyond the fragments the old file matched | why: the scenarios keep to the old fragments | revisit when: the migration series is done
2026-11-11 | excluded: new flow harness checks beyond tests/test_flow_deliver.sh (including a one-question case for deliver) | why: a migration adds no checks | revisit when: the migration series is done
2026-11-11 | excluded: the discover-only checks of tests/test_flow.sh in the deliver scenarios (missing claude, relative output folder, CRLF fixtures, runs with no answer) | why: they belong to the discover harness migration | revisit when: that migration is done
2026-11-11 | excluded: a real model run in the scenarios | why: the scenarios use a fake claude and a fake npm, as the bash file does | revisit when: never
2026-11-11 | removed: the exclusion of the discover-only checks of tests/test_flow.sh (missing claude, relative output folder, CRLF fixtures, runs with no answer) | why: the discover harness migration is now under way, so they are in scope | revisit when: never
2026-11-11 | excluded: new flow harness checks beyond tests/test_flow.sh and the one install.sh guard rail | why: a migration adds no checks | revisit when: the migration series is done
2026-11-11 | excluded: deleting tests/test_flow.sh in the discover migration PR | why: the builder runs a mutation check against it first and deletes it afterwards | revisit when: the mutation check is done
2026-11-11 | excluded: new eval checks beyond tests/test_evals.sh (a real claude plugin eval run, the arguments the runner passes through, the copy-back of results) | why: a migration adds no checks | revisit when: the migration series is done
2026-11-11 | excluded: deleting tests/test_evals.sh in the evals migration PR | why: the builder runs a mutation check against it first and deletes it afterwards | revisit when: the mutation check is done
2026-11-11 | excluded: new red-first or known-gaps checks beyond tests/test_red_first.sh (deliver.md mentioning red-first, a count of each part per gap) | why: a migration adds no checks | revisit when: the migration series is done
2026-11-11 | excluded: deleting tests/test_red_first.sh in the red-first migration PR | why: the builder runs a mutation check against it first and deletes it afterwards | revisit when: the mutation check is done
2026-11-11 | excluded: new deliver text checks beyond tests/test_deliver.sh (the allowed-tools check and the no-developer index line are covered by other scenarios, and the default out-of-scope row check stays in tests/test_skills.sh) | why: a migration adds no checks | revisit when: the migration series is done
2026-11-11 | excluded: new plugin checks beyond tests/test_plugin.sh | why: a migration adds no checks | revisit when: the migration series is done
2026-11-11 | excluded: a scenario for the install.sh source line (test_plugin.sh line 79) | why: install-fresh-files.feature already runs the installer and checks the source line | revisit when: that scenario is removed
2026-11-11 | excluded: any change to a file under plugin/ | why: the scenarios read the plugin as it is | revisit when: a check finds a real gap
2026-11-12 | excluded: new text checks beyond tests/test_skills.sh | why: a migration adds no checks | revisit when: the migration series is done
2026-11-12 | excluded: scenarios for the three assert_no_added_emdash calls in tests/test_skills.sh | why: the repo-wide em-dash scan reads whole files and covers them | revisit when: that scan is removed
2026-11-12 | excluded: scenarios for phrases that deliver-shape, plugin-text-rules and plugin-renames-and-text already hold | why: a scenario that another covers adds nothing | revisit when: one of those scenarios is removed
2026-11-12 | excluded: scenarios for the plugin note to run /bdd:init and the decisions.sh plugin path in design and implement | why: plugin-text-rules already holds them | revisit when: that scenario is removed
2026-11-12 | excluded: a mutation run by the agent in PR 2 of 3 | why: the builder runs the mutation check as the red proof | revisit when: the builder asks for it
2026-11-12 | excluded: a mutation run by the agent in PR 3 of 3 | why: the builder runs the mutation check as the red proof | revisit when: the builder asks for it
2026-11-12 | excluded: tighter versions of the short triage words (open, change, question, approve) | why: a migration adds no checks | revisit when: the migration series is done
2026-11-12 | excluded: scenarios for README phrases that readme-order and readme-folded already hold, and for the reconciler and feedback-intake rows | why: a scenario that another covers adds nothing | revisit when: one of those scenarios is removed
2026-11-12 | excluded: a cross-check that each flag and code named in reconcile.md is accepted by decisions.sh | why: the approach review kept the phrase checks and did not add checks | revisit when: the reconcile text or the script changes
2026-11-12 | excluded: running a subset of the eval cases or the flow harness on every push | why: they cost money and the approach review did not change them | revisit when: G7 or G12 is worked on
2026-11-12 | excluded: scenarios for the install, flow harness and eval survivors in the decisions survivors change | why: each needs a look at the code first, and the decisions script was the largest group | revisit when: the next change on the installer or the flow harness
2026-11-12 | excluded: scenarios for the two equivalent mutants of the decisions script | why: no input can tell the two versions apart | revisit when: the append check is rewritten
