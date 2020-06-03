#!/bin/bash

#
# -  Permission Needed
# -     "s3:PutObject", "ec2:TerminateInstances"
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
S3_BUCKET="<dest-bucket>"
S3_PATH="<dest-bucket-path>"
DATA_FOLDER="data"

echo '[mongodb-org-3.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/3.0/x86_64/
gpgcheck=0
enabled=1' > /etc/yum.repos.d/mongodb-org-3.0.repo

yum update -y
yum install -y mongodb-org

mkdir -p "$DATA_FOLDER"
mongodump --host "$DB_HOST" --port "$DB_PORT" --username "$DB_USERNAME" --password "$DB_PASSWORD" --out "$DATA_FOLDER/"  --quiet;
aws s3 cp "$DATA_FOLDER" s3://"$S3_BUCKET""$S3_PATH" --recursive --no-progress;

echo "FINISHED - Turning Off !"

REGION=`curl http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`;
aws ec2 terminate-instances --region "$REGION" --instance-ids $(curl http://169.254.169.254/latest/meta-data/instance-id);

