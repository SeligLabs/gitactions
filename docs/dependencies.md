# Dependencies

Template: none
Changes land by: push to main
Checks: in `condition/` and in `read-json-file/`, `corepack yarn@1.22.22 install --frozen-lockfile && corepack yarn@1.22.22 build`, then `git diff --exit-code -- condition/dist read-json-file/dist`; `bash -n` and `shellcheck` on every shell script touched

## Held back

| Upgrade | Why | Revisit when |
| --- | --- | --- |

## Notes

- There is no CI check, and a push to main is itself a release: unless it touches only `**.md`, `LICENSE`, `.gitignore` or `release.yml`, `release.yml` cuts the next patch and moves `v1`, which every caller runs. Test before committing; nothing stands between the push and the callers.
- `condition/` and `read-json-file/` have Yarn 1 lockfiles. Use `corepack yarn@1.22.22`, never a newer `yarn`, and commit the rebuilt `dist/index.js` whenever their dependencies move.
- `invalidate-cloudfront/invalidate.sh` downloads jq at run time, so its pin lives in the script: the version gate, the download URL and the name the binary is saved under, with the tool list in `invalidate-cloudfront/README.md`. Move all four together.
- `branch-name/action.yml` still uses the deprecated `::set-output` command. It is not a version and was left alone.

## Log

- 2026-11-27: routine (the `release-notes` README example now shows `actions/checkout@v7`); nothing else was behind in range.
