# pg2s3
Aurora PostgreSQL to S3 dump and restore

## Assumptions and Pre-Reqs
* Database username stored in AWS Secrets Manager with key/val as `{"DATABASE_USERNAME": "<USERNAME>"}`
* Database password stored in AWS Secrets Manager with key/val as `{"DATABASE_PASSWORD": "<PASSWORD>"}`
* S3 bucket pre-exists
* IAM role setup for S3 access and AWS crednetials are available as environment variables

## Examples
### pgdump to S3
PostgreSQL dump is stored in S3 as `s3://TARGET_S3_BUCKET/TARGET_S3_PATH/DATABASE_NAME-EPOCHTIME.sql.gz` with SSE AES256.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pgdump-to-s3
  labels:
    app: pgdump-to-s3
spec:
  template:
    metadata:
      annotations:
        # Example using kube2iam annotation
        iam.amazonaws.com/role: arn:aws:iam::0123456789:role/pg-aurora139-example
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - name: psqlclient
        image: knowshan/pg2s3:latest
        imagePullPolicy: Always
        command: ["/src/backup_to_s3.sh"]
        env:
        - name: DATABASE_HOST
          value: "pg-aurora139-example.cluster-oc3qnn.us-east-1.rds.amazonaws.com"
        - name: DATABASE_NAME
          value: "amazon"
        - name: DATABASE_USER_SECRET_ID
          value: "pg-aurora139-example/DB_USER"
        - name: DATABASE_PASSWORD_SECRET_ID
          value: "pg-aurora139-example/DB_PASSWORD"
        - name: TARGET_S3_BUCKET
          value: "bucket-name"
        - name: TARGET_S3_PATH
          value: "rds/backups"
      restartPolicy: Never
  backoffLimit: 4
```

### Restore from S3
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pg-from-s3
  labels:
    app: pg-from-s3
spec:
  template:
    metadata:
      annotations:
        # Example using kube2iam annotation
        iam.amazonaws.com/role: arn:aws:iam::0123456789:role/pg-aurora139-example
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - name: psqlclient
        image: knowshan/pg2s3:latest
        imagePullPolicy: Always
        command: ["/src/restore_from_s3.sh"]
        env:
        - name: DATABASE_HOST
          value: "pg-aurora139-example.cluster-oc3qnn.us-east-1.rds.amazonaws.com"
        - name: DATABASE_NAME
          value: "amazon"
        - name: DATABASE_USER_SECRET_ID
          value: "pg-aurora139-example/DB_USER"
        - name: DATABASE_PASSWORD_SECRET_ID
          value: "pg-aurora139-example/DB_PASSWORD"
        - name: SOURCE_S3_PGDUMP_PATH
          value: "s3://bucket-name/rds/backup/amazon-1704947159.sql.gz"
      restartPolicy: Never
  backoffLimit: 4
```