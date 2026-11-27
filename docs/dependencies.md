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
- `invalidate-cloudfront/invalidate.sh` downloads jq at run time, so its pin (1.8.2) lives in the script: the version gate, the download URL and the name the binary is saved under, with the tool list in `invalidate-cloudfront/README.md`. Move all four together.
  - The gate is an exact match on `jq --version`, so the runner's own jq is used only when it is that very version. No hosted Ubuntu image has it yet (22.04 ships 1.6, 24.04 ships 1.7, 26.04 ships 1.8.1), so the download happens on every run.
  - The assets it asks for, `jq-linux64` and `jq-osx-amd64`, are jq's old names. 1.8.2 still publishes them as copies of `jq-linux-amd64` and `jq-macos-amd64`; check that a new release still has them before moving the pin.
  - To test a move without AWS: run the script's own jq line under the old and the new binary on sample `PATHS` values and compare the output. Never run the script against a real distribution to test it.
- `branch-name/action.yml` still uses the deprecated `::set-output` command. It is not a version and was left alone.

## Log

- 2026-11-27: routine (the `release-notes` README example now shows `actions/checkout@v7`); nothing else was behind in range. Security: jq 1.6 → 1.8.2 in `invalidate-cloudfront/invalidate.sh`, past the 20 advisories filed against 1.8.1 and older (three high: GHSA-cfh2-vwfq-qfmm, GHSA-wwj8-gxm6-jc29, GHSA-q3h9-m34w-h76f) and the ones fixed in 1.8.0 and 1.8.1.
