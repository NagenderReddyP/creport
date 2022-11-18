#!/bin/bash

#self configuration script INFRA
#exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

dnf install -y unzip
CLI="/usr/local/bin/aws"
[ ! -f $CLI ] && AWS_CLI_FILE="/opt/awscli.zip" && curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$AWS_CLI_FILE" && unzip -q "$AWS_CLI_FILE" && sh ./aws/install && rm -f "$AWS_CLI_FILE"

TOKEN=$(curl -sX PUT "http://instance-data/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID="$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://instance-data/latest/meta-data/instance-id)"
     REGION="$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://instance-data/latest/meta-data/placement/region)"
        Env=$($CLI ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=AwsEnv"  --region $REGION --output=text |cut -f5| awk '{print tolower($0)}')

# get the ansible playbook
aws s3 cp s3://creport-${Env}-s3-mgt/last/creport.zip  /tmp

rm -rf /tmp/ansible-pull-main ; cd /tmp && unzip /tmp/creport.zip

# execute bootstrap.sh
su - root -c "time sh /tmp/creport-main/scripts/bootstrap.sh | tee /tmp/bootstrap.log 2>&1 "