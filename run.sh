#!/bin/bash

cd "$WERCKER_SOURCE_DIR"

# Required parameters
if [ -z "$AWS_CODE_DEPLOY_APPLICATION_NAME" ]; then
  fail "deployment_application_name must be set in wercker.yml or AWS_CODE_DEPLOY_APPLICATION_NAME must be set in environment"
  exit 1
fi
if [ -z "$AWS_CODE_DEPLOY_S3_BUCKET" ]; then
  fail "s3-bucket must be set in wercker.yml or AWS_CODE_DEPLOY_S3_BUCKET must be set in environment"
  exit 1
fi

# Optional parameters
export AWS_DEPLOY_S3_SSE=${AWS_CODE_DEPLOY_S3_SSE:-true}

if [ -z "$AWS_CODE_DEPLOY_REVISION_DESCRIPTION" ]; then
  if [ -f "VERSION" ]; then
    export AWS_CODE_DEPLOY_REVISION_DESCRIPTION="Version $(cat VERSION), Git commit $WERCKER_GIT_COMMIT"
  else
    export AWS_CODE_DEPLOY_REVISION_DESCRIPTION="Git commit $WERCKER_GIT_COMMIT"
  fi
fi

export AWS_CODE_DEPLOY_DEPLOYMENT_DESCRIPTION="${AWS_CODE_DEPLOY_DEPLOYMENT_DESCRIPTION:-Deployed by Wercker on $(date), Wercker deployment ID $WERCKER_DEPLOY_ID}"

export AWS_CODE_DEPLOY_S3_KEY_PREFIX="${AWS_CODE_DEPLOY_S3_KEY_PREFIX:-$WERCKER_GIT_REPOSITORY/$WERCKER_DEPLOYTARGET_NAME}"

export AWS_CODE_DEPLOY_S3_FILENAME="${AWS_CODE_DEPLOY_S3_FILENAME:-${WERCKER_DEPLOY_ID}.zip}"

export AWS_CODE_DEPLOY_APP_SOURCE=${AWS_CODE_DEPLOY_APP_SOURCE:-$WERCKER_ROOT}

export AWS_CODE_DEPLOY_DEPLOYMENT_GROUP_NAME=${AWS_CODE_DEPLOY_DEPLOYMENT_GROUP_NAME:-$WERCKER_DEPLOYTARGET_NAME}

./bin/aws-code-deploy.sh


