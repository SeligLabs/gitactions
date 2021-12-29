#!/bin/sh

set -e

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "FATAL ERROR: AWS_ACCESS_KEY_ID is not set."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "FATAL ERROR: AWS_SECRET_ACCESS_KEY is not set."
  exit 1
fi

# Default to us-east-1 if AWS_REGION not set.
# if [ -z "$AWS_REGION" ]; then
#   echo "INFO: AWS_REGION is not set. Using us-east-1"
#   AWS_REGION="us-east-1"
# fi
if [ -z "$AWS_REGION" ]; then
  echo "FATAL ERROR: AWS_REGION is not set."
  exit 1
fi


if [ -z "$AWS_S3_BUCKET" ]; then
  echo "FATAL ERROR: AWS_S3_BUCKET is not set."
  exit 1
fi

# Override default AWS endpoint if user sets AWS_S3_ENDPOINT.
if [ -n "$AWS_S3_ENDPOINT" ]; then
  ENDPOINT_APPEND="--endpoint-url $AWS_S3_ENDPOINT"
fi

# Create a dedicated profile for this action to avoid conflicts
# with other actions.
aws configure --profile action-s3-sync <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

# Sync using the dedicated profile and suppress verbose messages.
# All other flags are optional via the `args:` directive.
sh -c "aws s3 sync ${SOURCE_DIR:-.} s3://${AWS_S3_BUCKET}/${DEST_DIR} \
              --profile s3-sync-action \
              --no-progress \
              ${ENDPOINT_APPEND} $*"

# Clear out credentials after we're done.
# Need to re-run `aws configure` with bogus input instead of
# deleting ~/.aws in case there are other credentials living there.
# https://forums.aws.amazon.com/thread.jspa?threadID=148833
aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
null
null
null
text
EOF