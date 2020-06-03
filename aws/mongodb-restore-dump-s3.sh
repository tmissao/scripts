#!/bin/bash

#
# -  Permission Needed On the Origin Role
# -     "s3:GetObject"
# -
# -  Permission Needed On Destination
# -     "ec2:TerminateInstances", "sts:AssumeRole"
#

# Debugging - prints every command and returns
set -x;
# Makes script exit if a commands fails
set -e;
# Makes de pipeline returns error if a command in pipeline fails
set -o pipefail;
# Makes script exit if a referenced variable is not declared
set -u;

# Variables
NOW=$(date +"%Y-%m-%d");
DB_HOST="<mongo-host>"
DB_PORT="27017"
DB_USERNAME="<mongo-username>"
DB_PASSWORD="<mongo-password>"
S3_BUCKET="<s3-origin-bucket-name>"
S3_PATH="<s3-origin-bucket-path>"
ROLE_ARN="<aws-iam-role-arn>"
DATA_FOLDER="data"

echo '[mongodb-org-3.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/3.0/x86_64/
gpgcheck=0
enabled=1' > /etc/yum.repos.d/mongodb-org-3.0.repo

yum update -y
yum install -y mongodb-org
yum install jq -y

wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem --quiet;
aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "EC2-Dump" > credentials.json;

set +x;
export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' credentials.json);
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' credentials.json);
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' credentials.json);
rm -rf credentials.json;
set -x;

mkdir -p "$DATA_FOLDER"
aws s3 cp s3://"$S3_BUCKET""$S3_PATH" "$DATA_FOLDER" --recursive --no-progress;

unset AWS_ACCESS_KEY_ID;
unset AWS_SECRET_ACCESS_KEY;
unset AWS_SESSION_TOKEN;

mongorestore --host "$DB_HOST" --port "$DB_PORT" --username "$DB_USERNAME" --password "$DB_PASSWORD" --ssl --sslCAFile ./rds-combined-ca-bundle.pem --drop "$DATA_FOLDER/"  --quiet;

echo "FINISHED - Turning Off !"

REGION=`curl http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`;
aws ec2 terminate-instances --region "$REGION" --instance-ids $(curl http://169.254.169.254/latest/meta-data/instance-id);

