#!/bin/bash

# Debugging - prints every command and returns
set -x;
# Makes script exit if a commands fails
set -e;
# Makes de pipeline returns error if a command in pipeline fails
set -o pipefail;
# Makes script exit if a referenced variable is not declared
set -u;

if [ -z "$1" ]; then
    echo "Missing MessageEncoded Argument"
    exit 1;
fi

# Variables
MESSAGE=$1
PROFILE=$2

if [[ -z "$PROFILE" ]]; then
  aws sts decode-authorization-message --encoded-message "$MESSAGE" --query DecodedMessage --output text | jq '.';
else
  aws sts decode-authorization-message --profile "$PROFILE" --encoded-message "$MESSAGE" --query DecodedMessage --output text | jq '.';
fi
