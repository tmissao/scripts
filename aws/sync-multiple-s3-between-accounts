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
S3_ORIGINS=( "<bucket-name>" )
S3_DESTS=( "<bucket-name>" )
ROLE_ARN="<aws-iam-role-arn>"
DATA_FOLDER="./data"
ALL_FOLDERS=()

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
for t in ${S3_ORIGINS[@]}; do
  S3_ORIGIN="s3://$t";
  S3_FOLDER="$DATA_FOLDER/$t";
  ALL_FOLDERS+=( $S3_FOLDER );
  mkdir -p "$S3_FOLDER"
  aws s3 cp "$S3_ORIGIN" "$S3_FOLDER" --recursive --no-progress
done;

# Release Role
unset AWS_ACCESS_KEY_ID;
unset AWS_SECRET_ACCESS_KEY;
unset AWS_SESSION_TOKEN;

for i in ${!ALL_FOLDERS[@]}; do
  S3_DEST="s3://${S3_DESTS[$i]}"
  aws s3 cp "${ALL_FOLDERS[$i]}" "$S3_DEST" --recursive --no-progress
done;

echo "FINISHED - Turning Off !"

REGION=`curl http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`;
aws ec2 terminate-instances --region "$REGION" --instance-ids $(curl http://169.254.169.254/latest/meta-data/instance-id);

