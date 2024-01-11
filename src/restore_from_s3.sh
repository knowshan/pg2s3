#!/bin/bash

REQUIRED_VARS=(DATABASE_HOST DATABASE_NAME DATABASE_USER_SECRET_ID DATABASE_PASSWORD_SECRET_ID SOURCE_S3_PGDUMP_PATH)
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

DATABASE_PASSWORD=${DATABASE_PASSWORD:-`aws secretsmanager get-secret-value --secret-id "$DATABASE_PASSWORD_SECRET_ID" --query SecretString --output text | jq -r .DATABASE_USERNAME`}`
if [[ -z "${DATABASE_PASSWORD}" ]]; then
  echo "Couldn't fetch $DATABASE_USER_SECRET_ID from Secrets Manager"
  exit 1
fi

export PGPASSWORD=${DATABASE_PASSWORD}
aws s3 cp --storage-class STANDARD_IA --sse aws:kms - ${SOURCE_S3_PGDUMP_PATH} ${DATABASE_NAME}.sql.gz
echo "Downloaded $SOURCE_S3_PGDUMP_PATH"
gunzip < ${DATABASE_NAME}.sql.gz | psql -h ${DATABASE_HOST} -U ${DATABASE_USER} -d ${DATABASE_NAME} 
rc=$?
unset PGPASSWORD

if [[ $rc != 0 ]]; then exit $rc; fi

echo "Done - psql import completed."
