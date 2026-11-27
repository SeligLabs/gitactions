#!/usr/bin/env bash
# Writes a release's version into the repository and commits it to the
# branch, so the tag lands on a commit that says which release it is.
#
# It releases only the branch's newest commit. If the branch moved on since
# this run's commit, a newer run is queued behind this one and releases both;
# this one stands down (RELEASE=false), so nothing reaches people ahead of its
# own checks. The one exception is this run's own version commit already
# sitting on top, left by an earlier attempt: then it carries on from there.
set -euo pipefail

: "${TAG:?TAG is required}"
: "${FILES:?FILES is required}"
: "${COMMAND:=}"
: "${BRANCH:=}"
: "${MESSAGE:=}"
: "${NO_VERIFY:=true}"

out() { echo "$1" >> "${GITHUB_OUTPUT:-/dev/stdout}"; }

BRANCH=${BRANCH:-$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')}
MESSAGE=${MESSAGE:-"chore(release): $TAG [skip ci]"}

git fetch --quiet origin "$BRANCH"
HERE=$(git rev-parse HEAD)
TIP=$(git rev-parse FETCH_HEAD)

if [[ "$TIP" != "$HERE" ]]; then
  if [[ "$(git log -1 --format=%s FETCH_HEAD)" == "$MESSAGE" &&
    "$(git rev-parse 'FETCH_HEAD^')" == "$HERE" ]]; then
    git checkout --quiet --detach FETCH_HEAD
    echo "The version commit for $TAG is already on $BRANCH; releasing it."
    out "RELEASE=true"
    out "COMMITTED=false"
    out "SHA=$TIP"
    exit 0
  fi
  echo "$BRANCH has moved on from this commit; the newer run releases it."
  out "RELEASE=false"
  out "COMMITTED=false"
  out "SHA=$HERE"
  exit 0
fi

if [[ -n "$COMMAND" ]]; then
  bash -c "$COMMAND"
fi

# shellcheck disable=SC2086  # FILES is a space-separated list of paths or globs
git add -- $FILES
if git diff --cached --quiet; then
  # Already stamped, e.g. a run whose tag step failed before this one.
  echo "Nothing to commit: $BRANCH already carries $TAG."
  out "RELEASE=true"
  out "COMMITTED=false"
  out "SHA=$HERE"
  exit 0
fi

HOOKS=()
[[ "$NO_VERIFY" == "true" ]] && HOOKS=(--no-verify)
git -c user.name="github-actions[bot]" \
  -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
  commit --quiet "${HOOKS[@]}" -m "$MESSAGE"
# A push made with the workflow's GITHUB_TOKEN starts no new run, so this
# cannot loop; [skip ci] in the default message covers other credentials.
git push --quiet origin "HEAD:$BRANCH"

out "RELEASE=true"
out "COMMITTED=true"
out "SHA=$(git rev-parse HEAD)"
echo "Committed $TAG to $BRANCH."
