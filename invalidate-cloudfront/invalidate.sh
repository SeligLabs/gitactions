#!/bin/bash

set -eo pipefail

#####################
# Check Configuration
#####################
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "FATAL ERROR: AWS_ACCESS_KEY_ID is not set."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "FATAL ERROR: AWS_SECRET_ACCESS_KEY is not set."
  exit 1
fi

# Default to us-east-1 if AWS_REGION not set.
if [ -z "$AWS_REGION" ]; then
  echo "INFO: AWS_REGION is not set. Using us-east-1."
  AWS_REGION="us-east-1"
fi


if [ -z "$DISTRIBUTION" ]; then
  echo "FATAL ERROR: DISTRIBUTION is not set."
  exit 1
fi

if [[ -z "$PATHS" && -z "$PATHS_FROM" ]]; then
  echo "FATAL ERROR: PATHS or PATHS_FROM is not set."
  exit 1
fi

##################
# Setup Enviorment
##################
# Create a dedicated profile for this action to avoid conflicts
# with other actions.
aws configure --profile seliglabs-invalidate-cloudfront <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

# Set it here to avoid logging keys/secrets
if [ "$DEBUG" = "1" ]; then
  echo "*** Enabling debug output (set -x)"
  set -x
fi

# Ensure we have jq-1.8.2
jq="jq"
if  [[ ! -x "$(command -v $jq)" || "$($jq --version)" != "jq-1.8.2" ]]; then
  if [[ $(uname) == "Darwin" ]]; then
    jqbin="jq-osx-amd64"
  elif [[ $(uname) == "Linux" ]]; then
    jqbin="jq-linux64"
  fi
  if [[ -n "$jqbin" ]]; then
    jq="/usr/local/bin/jq182"
    wget -O $jq https://github.com/jqlang/jq/releases/download/jq-1.8.2/$jqbin
    chmod 755 $jq
  fi
fi

#########
# Execute
#########
if [[ -n "$PATHS_FROM" ]]; then
  echo "*** Reading PATHS from $PATHS_FROM"
  if [[ ! -f  $PATHS_FROM ]]; then
    echo "PATHS file not found. nothing to do. exiting"
    exit 0
  fi
  PATHS=$(cat $PATHS_FROM | tr '\n' ' ')
  echo "PATHS=$PATHS"
  if [[ -z "$PATHS" ]]; then
    echo "PATHS is empty. nothing to do. exiting"
    exit 0
  fi
fi

# Handle multiple space-separated paths, particularly containing wildcards.
# i.e., if PATHS="/* /foo"
IFS=' ' read -r -a PATHS_ARR <<< "$PATHS"
echo -n "${PATHS}" > "${RUNNER_TEMP}/paths.txt"
JSON_PATHS=$($jq --null-input --compact-output --monochrome-output --rawfile inarr "${RUNNER_TEMP}/paths.txt" '$inarr | rtrimstr(" ") | rtrimstr("\n") | split(" ")')
LEN="${#PATHS_ARR[@]}"
CR="$(date +"%s")$RANDOM"
cat <<-EOF > "${RUNNER_TEMP}/invalidation-batch.json"
{ "InvalidationBatch": { "Paths": { "Quantity": ${LEN}, "Items": ${JSON_PATHS} }, "CallerReference": "${CR}" } }
EOF

if [ "$DEBUG" = "1" ]; then
  echo "> wrote ${RUNNER_TEMP}/invalidation-batch.json"
  cat "${RUNNER_TEMP}/invalidation-batch.json"
fi

# Use our dedicated profile and suppress verbose messages.
# Support v1.x of the awscli which does not have this flag
[[ "$(aws --version)" =~ "cli/2" ]] && pagerflag="--no-cli-pager"
aws $pagerflag --profile seliglabs-invalidate-cloudfront \
  cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION" \
  --cli-input-json "file://${RUNNER_TEMP}/invalidation-batch.json"

##########
# Clean Up
##########
# Clear out credentials after we're done.
# Need to re-run `aws configure` with bogus input instead of
# deleting ~/.aws in case there are other credentials living there.
# https://forums.aws.amazon.com/thread.jspa?threadID=148833
aws configure --profile seliglabs-invalidate-cloudfront <<-EOF > /dev/null 2>&1
null
null
null
text
EOF
