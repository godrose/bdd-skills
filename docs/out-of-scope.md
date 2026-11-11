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
