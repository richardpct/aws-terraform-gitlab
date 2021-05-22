#!/bin/bash

set -x

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
yum -y update
yum -y install docker
yum -y install git
service docker start
cd /tmp
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/rpm/gitlab-runner_amd64.rpm"
rpm -i gitlab-runner_amd64.rpm
gitlab-runner register \
  --non-interactive \
  --url "http://${alb_internal_dns_name}" \
  --clone-url "http://${alb_internal_dns_name}" \
  --registration-token "${gitlab_token}" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "docker-runner"
