#!/bin/bash

REQUIRED_VARS=(DATABASE_HOST DATABASE_NAME DATABASE_USER_SECRET_ID DATABASE_PASSWORD_SECRET_ID TARGET_S3_BUCKET TARGET_S3_PATH)
REQUIRED_VARS_MISSING=false
for v in "${REQUIRED_VARS[@]}"
do
  if [ -z "${!v}" ]; then
    echo "Set $v environment variable"
    REQUIRED_VARS_MISSING=true
  fi
done

if [ "$REQUIRED_VARS_MISSING" = true ]; then
  exit 1
fi

DATABASE_USER=${DATABASE_USER:-`aws secretsmanager get-secret-value --secret-id  "$DATABASE_USER_SECRET_ID" --query SecretString --output text | jq -r .DATABASE_USERNAME`}
if [[ -z "${DATABASE_USER}" ]]; then
  echo "Couldn't fetch $DATABASE_USER_SECRET_ID from Secrets Manager"
  exit 1
fi
echo "User is: "
echo $DATABASE_USER

DATABASE_PASSWORD=${DATABASE_PASSWORD:-`aws secretsmanager get-secret-value --secret-id "$DATABASE_PASSWORD_SECRET_ID" --query SecretString --output text | jq -r .DATABASE_PASSWORD`}
if [[ -z "${DATABASE_PASSWORD}" ]]; then
  echo "Couldn't fetch $DATABASE_USER_SECRET_ID from Secrets Manager"
  exit 1
fi


EPOCH=$(date +%s)
PGDUMP_TARGET="s3://${TARGET_S3_BUCKET}/${TARGET_S3_PATH}/${DATABASE_NAME}-${EPOCH}.sql.gz"

echo Backing up ${DATABASE_HOST}/${DATABASE_NAME} to ${TARGET}

export PGPASSWORD=${DATABASE_PASSWORD}
pg_dump -Z 9 -v -h ${DATABASE_HOST} -U ${DATABASE_USER} -d ${DATABASE_NAME} | aws s3 cp --sse AES256 - ${PGDUMP_TARGET}
rc=$?
export PGPASSWORD=

if [[ $rc != 0 ]]; then 
  echo "Failed to copy pgdump"
  exit $rc
fi

echo Done
