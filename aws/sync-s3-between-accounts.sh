#!/bin/bash

#
# -  Permission Needed On the Origin Role
# -     "s3:GetObject"
# -
# -  Permission Needed On Destination
# -     "s3:PutObject", "ec2:TerminateInstances", "sts:AssumeRole"
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

S3_ORIGIN="s3://<origin-bucket-name>"
S3_DEST="s3://<dest-bucket-name>/"
ROLE_ARN="<origin-role-arn>"
DATA_FOLDER="./data"

yum update -y
yum install jq -y

# Assuming Role
aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "EC2-Dump" > credentials.json;

set +x;
export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' credentials.json);
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' credentials.json);
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' credentials.json);
rm -rf credentials.json;
set -x;

# Get S3 Data
mkdir "$DATA_FOLDER";
aws s3 cp "$S3_ORIGIN" "$DATA_FOLDER" --recursive --no-progress

# Release Role
unset AWS_ACCESS_KEY_ID;
unset AWS_SECRET_ACCESS_KEY;
unset AWS_SESSION_TOKEN;

# Put S3 Data
aws s3 cp "$DATA_FOLDER" "$S3_DEST" --recursive --no-progress

echo "FINISHED - Turning Off !"

REGION=`curl http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`;
aws ec2 terminate-instances --region "$REGION" --instance-ids $(curl http://169.254.169.254/latest/meta-data/instance-id);

