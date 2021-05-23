#!/bin/bash

set -x

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
mkdir /var/opt/gitlab
echo '${efs_dns_name}:/ /var/opt/gitlab nfs4 vers=4.1,hard,rsize=1048576,wsize=1048576,timeo=600,retrans=2,noresvport 0 2' >> /etc/fstab
mount /var/opt/gitlab
sudo yum -y update
sudo yum -y upgrade
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | bash
EXTERNAL_URL="http://${alb_dns_name}" yum install -y gitlab-ee
cat << EOF >> /etc/gitlab/gitlab.rb
postgresql['enable'] = false
gitlab_rails['db_adapter'] = "postgresql"
gitlab_rails['db_encoding'] = "unicode"
gitlab_rails['db_database'] = "gitlabhq_production"
gitlab_rails['db_username'] = "${postgres_user}"
gitlab_rails['db_password'] = "${postgres_pass}"
gitlab_rails['db_host'] = "${postgres_address}"

redis['enable'] = false
gitlab_rails['redis_host'] = "${redis_address}"
gitlab_rails['redis_port'] = 6379
EOF
gitlab-ctl reconfigure
