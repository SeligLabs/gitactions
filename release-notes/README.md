# Release Notes

Writes release notes for a tag to a file, ready for `gh release create --notes-file`.

It prefers a summary of the commits written by [Claude](https://docs.claude.com/en/api/). When that isn't available (no API key, call fails, is refused, comes back empty, etc.) it falls back to **GitHub's own generated notes**, requested through the [releases API](https://docs.github.com/en/rest/releases/releases#generate-release-notes-content-for-a-release), the same content `gh release create --generate-notes` would produce.

So the caller needs no fallback branch of its own: the file is there either way, and `SOURCE` says where it came from. The notes are a nicety and never a gate; the action succeeds even when neither source is available, writing a placeholder and reporting `SOURCE=none`, so a release is never blocked on them.

## Usage

The action reads history with `git log`, so the calling job must check out with `fetch-depth: 0` — a shallow checkout has nothing to summarise.

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: Write Release Notes
        id: notes
        uses: SeligLabs/gitactions/release-notes@v1
        with:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          TAG: v1.4.0
          PREVIOUS_TAG: v1.3.0
          COMPARE_BASE: ${{ github.server_url }}/${{ github.repository }}/compare
          PROJECT_DESCRIPTION: a marketing site built with Next.js

      - name: Create Release
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh release create v1.4.0 --notes-file "${{ steps.notes.outputs.NOTES_FILE }}"
```

### Inputs

| Key                   | Value                                                                                                                                                                       | Required | Default                         |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------- |
| `ANTHROPIC_API_KEY`   | An Anthropic API key, as a [secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets). Unset means the summary is skipped and generated notes are used. | No       | `""`                            |
| `TAG`                 | The tag being released. Used for the compare link.                                                                                                                          | **Yes**  | N/A                             |
| `PREVIOUS_TAG`        | The tag to summarise from, exclusive. Unset summarises the whole history, which is what a first release wants.                                                              | No       | `""`                            |
| `COMPARE_BASE`        | Base URL for the full-changelog link appended to a Claude summary. Omit to append no link. Generated notes carry their own.                                                 | No       | `""`                            |
| `FALLBACK`            | Whether to use GitHub's generated notes when no summary is produced. `"false"` leaves the notes empty instead.                                                              | No       | `"true"`                        |
| `GITHUB_TOKEN`        | Token used to request generated notes.                                                                                                                                      | No       | `${{ github.token }}`           |
| `MODEL`               | The Claude model to summarise with.                                                                                                                                         | No       | `claude-opus-5`                 |
| `PROJECT_DESCRIPTION` | What the project is, in a few words, so the notes are written in the right register. Reaches the model verbatim.                                                            | No       | `a software project`            |
| `MAX_WORDS`           | Upper bound on the length of the notes.                                                                                                                                     | No       | `200`                           |
| `NOTES_FILE`          | Where to write the notes.                                                                                                                                                   | No       | `$RUNNER_TEMP/release-notes.md` |

### Outputs

| Key          | Value                                                                                                                  |
| ------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `SOURCE`     | `"claude"` for a summary, `"github"` for generated notes, `"none"` if neither was available.                           |
| `NOTES_FILE` | Path to the notes. Always written — a placeholder when `SOURCE` is `"none"` — so it can go straight to `--notes-file`. |

## Notes

- Commit subjects reach the model as data: the request body is built with `jq`, so quotes, backticks, `$(...)` and newlines in a commit message can't break it.
- The model is asked to skip dependency bumps, formatting and lockfile churn, and to lead with what changed for someone using the project rather than with file names.
- Falling back needs the token to be able to read the repository, which the default `${{ github.token }}` can.
- Requires `curl` and `jq`, both present on GitHub-hosted runners.
