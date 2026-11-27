# Commit Version

Writes a release's version into the repository, commits it to the branch as `chore(release): vX.Y.Z [skip ci]` and pushes, so the tag that follows lands on a commit that says which release it is. The job needs `contents: write` and `fetch-depth: 0`.

It releases only the branch's newest commit. When the branch has moved on since this run's commit, a newer run is queued behind this one and will release both, so this one sets `RELEASE` to `false` and stops: nothing reaches people ahead of its own checks. Gate the tag step on that output.

It is safe to re-run. If an earlier attempt already pushed the version commit and then failed, it checks that commit out and carries on. If the files already carry the version, it commits nothing and carries on.

```yaml
steps:
  - uses: actions/checkout@v7
    with:
      fetch-depth: 0
  - id: version
    uses: SeligLabs/actionKit/next-version@v1
  - id: commit
    uses: SeligLabs/actionKit/commit-version@v1
    with:
      TAG: ${{ steps.version.outputs.TAG }}
      FILES: package.json
      COMMAND: npm version --no-git-tag-version ${{ steps.version.outputs.VERSION }}
  - if: steps.commit.outputs.RELEASE == 'true'
    uses: SeligLabs/actionKit/tag-release@v1
    with:
      TAG: ${{ steps.version.outputs.TAG }}
```

| Input       | Value                                                                                   | Default                         |
| ----------- | --------------------------------------------------------------------------------------- | ------------------------------- |
| `TAG`       | The release, e.g. `v1.4.0`.                                                             | required                        |
| `FILES`     | Files the version is written to, space-separated; globs work.                           | required                        |
| `COMMAND`   | Shell command that writes the version. Runs only when this run releases.                | none                            |
| `BRANCH`    | Branch to commit to.                                                                    | the default branch              |
| `MESSAGE`   | Commit message.                                                                         | `chore(release): TAG [skip ci]` |
| `NO_VERIFY` | `"true"` skips git hooks on the commit.                                                 | `"true"`                        |

| Output      | Value                                                                    |
| ----------- | ------------------------------------------------------------------------ |
| `RELEASE`   | `"true"` when this run should tag and release; `"false"` when a newer run will. |
| `COMMITTED` | `"true"` when this run pushed a version commit.                          |
| `SHA`       | The commit to tag, checked out.                                          |

A commit marked `[skip release]` that lands behind a releasable one makes the earlier run stand down and releases nothing itself, so that change waits for the next release.
