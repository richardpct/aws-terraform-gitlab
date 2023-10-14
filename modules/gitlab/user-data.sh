#!/bin/bash

set -x -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
mkdir /var/opt/gitlab-nfs
echo '${efs_dns_name}:/ /var/opt/gitlab-nfs nfs4 vers=4.1,hard,rsize=1048576,wsize=1048576,timeo=600,retrans=2,noresvport 0 2' >> /etc/fstab
mount /var/opt/gitlab-nfs
sudo yum -y update
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

git_data_dirs({"default" => { "path" => "/var/opt/gitlab-nfs/gitlab-data/git-data"} })
gitlab_rails['uploads_directory'] = '/var/opt/gitlab-nfs/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/var/opt/gitlab-nfs/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/var/opt/gitlab-nfs/gitlab-data/builds'
EOF
gitlab-ctl reconfigure

sudo gitlab-rake "gitlab:password:reset[root]" << EOF
${gitlab_pass}
${gitlab_pass}
EOF

echo "DONE"
