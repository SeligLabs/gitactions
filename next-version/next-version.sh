#!/usr/bin/env bash
# Works out the next vX.Y.Z from the newest tag of that shape. Moving major
# tags (v1) and build tags (v1.2.3+4) are not releases and are passed over.
set -euo pipefail

: "${BUMP:=patch}"
: "${INITIAL:=}"

if [[ "$(git rev-parse --is-shallow-repository)" == "true" ]]; then
  echo "::error::Check out with fetch-depth: 0 — the version comes from the tags."
  exit 1
fi

PREVIOUS=$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname |
  grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 || true)

if [[ -z "$PREVIOUS" ]]; then
  if [[ -z "$INITIAL" ]]; then
    echo "::error::No vX.Y.Z tag to advance from. Set INITIAL (for example v0.0.0) to start one."
    exit 1
  fi
  if [[ ! "$INITIAL" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "::error::INITIAL must look like v0.0.0, not '$INITIAL'."
    exit 1
  fi
  BASE=$INITIAL
else
  BASE=$PREVIOUS
fi

IFS=. read -r MAJOR MINOR PATCH <<< "${BASE#v}"
case "$BUMP" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  *)
    echo "::error::BUMP must be patch, minor or major, not '$BUMP'."
    exit 1
    ;;
esac

VERSION=$MAJOR.$MINOR.$PATCH
{
  echo "TAG=v$VERSION"
  echo "VERSION=$VERSION"
  echo "MAJOR=v$MAJOR"
  echo "PREVIOUS=$PREVIOUS"
} >> "${GITHUB_OUTPUT:-/dev/stdout}"
echo "Next version: v$VERSION (previous: ${PREVIOUS:-none})"
