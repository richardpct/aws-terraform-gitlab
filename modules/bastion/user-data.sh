#!/bin/bash

set -x -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INSTANCE_ID="$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)"
aws --region eu-west-3 ec2 associate-address --instance-id $INSTANCE_ID --allocation-id ${eip_bastion_id}
echo "DONE"
