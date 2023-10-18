#!/bin/bash

set -x -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
  git \
  docker.io
service docker start
cd /tmp
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb"
dpkg -i gitlab-runner_amd64.deb
gitlab-runner register \
  --non-interactive \
  --url "http://${alb_internal_dns_name}" \
  --clone-url "http://${alb_internal_dns_name}" \
  --registration-token "${gitlab_token}" \
  --executor "docker" \
  --docker-image "docker:24.0.5" \
  --description "docker-runner" \
  --docker-privileged \
  --docker-volumes "/certs/client"
[ -f /var/run/reboot-required ] && shutdown -r now
