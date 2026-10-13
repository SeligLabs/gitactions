# Tag & Release

Tags the checked-out commit and creates a GitHub release, with notes from [`release-notes`](../release-notes): summarised by Claude, or GitHub's generated notes when no summary is available.

It is safe to re-run. A tag that already exists isn't moved, and a release that already exists is left alone. So a job that failed between pushing the tag and creating the release can simply be retried.

The action doesn't choose the version. The caller passes the tag, so it fits any scheme: `v1.4.0`, or `v1.4.0+12` with a build number.

## Usage

The calling job must check out the commit to tag with `fetch-depth: 0`, since the notes need the history and the tags. It also needs `contents: write`.

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0

      - name: Tag & Release
        uses: SeligLabs/gitactions/tag-release@v1
        with:
          TAG: v${{ steps.version.outputs.version }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          PROJECT_DESCRIPTION: a marketing site built with Next.js
```

### Inputs

| Key                   | Value                                                                                                                            | Required | Default               |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------- | -------- | --------------------- |
| `TAG`                 | The tag to create.                                                                                                               | **Yes**  | N/A                   |
| `TITLE`               | The release title.                                                                                                               | No       | the tag               |
| `PREVIOUS_TAG`        | The tag to write notes from, exclusive. Unset takes the newest other tag matching `TAG_PATTERN`, or the whole history.           | No       | `""`                  |
| `TAG_PATTERN`         | Glob for the tags that count as releases when looking up `PREVIOUS_TAG`. Keep it narrow enough to skip hand-made or legacy tags. | No       | `v[0-9]*`             |
| `ANTHROPIC_API_KEY`   | An Anthropic API key, as a secret. Unset means GitHub's generated notes are used.                                                | No       | `""`                  |
| `PROJECT_DESCRIPTION` | What the project is, in a few words, so the summary is written in the right register.                                            | No       | `a software project`  |
| `MODEL`               | The Claude model to summarise with.                                                                                              | No       | `claude-opus-5`       |
| `GITHUB_TOKEN`        | Token used to push the tag and create the release.                                                                               | No       | `${{ github.token }}` |

### Outputs

| Key       | Value                                                                                                  |
| --------- | ------------------------------------------------------------------------------------------------------ |
| `CREATED` | `"true"` when this run created the tag or the release.                                                 |
| `URL`     | The release's URL.                                                                                     |
| `SOURCE`  | Where the notes came from: `"claude"`, `"github"` or `"none"`. Empty when the release already existed. |

It also adds a short "Release" section to the job summary.

# Sanity + Vercel workflow

[`.github/workflows/sanity-vercel.yml`](../.github/workflows/sanity-vercel.yml) is the full pipeline for monorepos built on SeligLabs/template-website, as a reusable workflow:

1. **Verify:** checks the Sanity types are fresh, then lint, type-check and test.
2. **Version:** keeps the root version if its tag is free, otherwise runs `pnpm version:patch` and commits the bump.
3. **Deploy:** runs each app's `deploy:prod` in parallel.
4. **Release:** runs this action.

Version, deploy and release run only on a push to the default branch. Setting `release: false` turns them off, which suits a template repository.

```yaml
name: Deploy Project

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  pipeline:
    uses: SeligLabs/gitactions/.github/workflows/sanity-vercel.yml@v1
    permissions:
      contents: write
    secrets:
      SANITY_AUTH_TOKEN: ${{ secrets.SANITY_AUTH_TOKEN }}
      VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
      SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
    with:
      project-description: a company website built as a monorepo
```

| Input                 | Value                                                                | Default             |
| --------------------- | -------------------------------------------------------------------- | ------------------- |
| `project-description` | What the project is, for the release notes. **Required.**            | N/A                 |
| `projects`            | JSON array of the `apps/*` folders to deploy.                        | `["studio", "web"]` |
| `tag-pattern`         | Glob for the tags that count as releases.                            | `v[0-9]*`           |
| `release`             | Whether a push to the default branch versions, deploys and releases. | `true`              |

Secrets, passed explicitly (`secrets: inherit` only reaches a workflow in the same organization): `SANITY_AUTH_TOKEN`, `VERCEL_TOKEN`, and the optional `SENTRY_AUTH_TOKEN` (source maps) and `ANTHROPIC_API_KEY` (release notes). The repository must also have a `.nvmrc`.
