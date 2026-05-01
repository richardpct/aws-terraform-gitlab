## Purpose

This tutorial is intended to show you how to build Gitlab on AWS automated with
OpenTofu, the source code can be found [here](https://github.com/richardpct/aws-terraform-gitlab).

The following figure depicts the infrastructure that you will build:

<img src="https://raw.githubusercontent.com/richardpct/images/master/aws-tuto-gitlab/image01.png">

Gitlab is one of the most used Git repository manager in the world, in
addition you may use the CI/CD feature called `Runners`.<br />
For building the Gitlab infrastructure I have followed the official Gitlab
installation that you can found [here](https://docs.gitlab.com/ee/install/aws/),
except I don't use a separate Gitaly service for managing the Git repositories,
I prefer to use a shared NFS instead of S3 because I want to simplify the
architecture.

## Configuring the network

#### envs/dev/01-network/main.tf

The following code shows how the network is split into subnets:

```
module "network" {
  source                  = "../../../modules/network"
  aws_profile             = var.aws_profile
  region                  = var.region
  env                     = "dev"
  vpc_cidr_block          = "10.0.0.0/16"
  subnet_public           = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  subnet_private_gitlab   = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  subnet_private          = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
  cidr_allowed_ssh        = var.my_ip_address
  ssh_public_key          = var.ssh_public_key
}
```

The subnets are organized as follows:

  - Public subnet:
    - The bastion server is the only one that allows you to connect via ssh to
the Gitlab server and Runner
    - The NAT Gateway allows the services located in the gitlab private subnet
(Gitlab and Runner) to access the Internet
    - The internet facing Load Balancer will forward the client http requests
to the Gitlab server
  - Private subnet (No access to Internet because not route to the NAT GW):
    - The internal Load Balancer allows the runners to reach the Gitlab server
    - The PostgreSQL and Redis databases using the AWS managed services
    - The EFS stores all Gitlab datas
  - Private Gitlab subnet (able to access to Internet):
    - The Gitlab servers and the Runners need to reach the Internet in order to
fetch and upgrade packages


#### modules/network/main.tf

  - Creating the VPC and the Internet Gateway:

```
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "my_vpc-${var.env}"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw-${var.env}"
  }
}
```

  - Creating all subnets:

```
resource "aws_subnet" "public" {
  count             = length(var.subnet_public)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_public[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "subnet_public-${var.env}-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.subnet_private)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "subnet_private-${var.env}-${count.index}"
  }
}

resource "aws_subnet" "private_gitlab" {
  count             = length(var.subnet_private_gitlab)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private_gitlab[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "subnet_private_gitlab-${var.env}-${count.index}"
  }
}
```

As you can see, all subnets are created into 3 availability zones, thus if an
outage occurs in a entire data center, the entire service will run into the
other availability zone.

  - Creating the NAT Gateway:

```
resource "aws_eip" "nat" {
  count  = length(var.subnet_public)
  domain = "vpc"

  tags = {
    Name = "eip_nat-${var.env}-${count.index}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.subnet_public)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat_gw-${var.env}-${count.index}"
  }
}
```

I remind you that the Nat Gateway is used so that the gitlab private subnet can
reach the Internet.

  - Creating the route tables:

```
resource "aws_route_table" "route_nat" {
  count  = length(var.subnet_public)
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "default_route-${var.env}-${count.index}"
  }
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "custom_route-${var.env}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.subnet_public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "private_gitlab" {
  count          = length(var.subnet_private_gitlab)
  subnet_id      = aws_subnet.private_gitlab[count.index].id
  route_table_id = aws_route_table.route_nat[count.index].id
}
```

I remind you that the private subnet has not route to the nat gateway, because
it hosts the managed aws services: elasticache, postgres and efs. They don't need
to access to Internet.

  - Creating the EIP for the bastion server:

```
resource "aws_eip" "bastion" {
  domain = "vpc"

  tags = {
    Name = "eip_bastion-${var.env}"
  }
}
```

## Creating the EFS

#### envs/dev/01-network/efs.tf

```
resource "aws_efs_file_system" "gitlab" {
  tags = {
    Name = "gitlab-efs-${var.env}"
  }
}

resource "aws_efs_mount_target" "gitlab" {
  count           = length(var.subnet_private)
  file_system_id  = aws_efs_file_system.gitlab.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
```

## Configuring the firewall rules

#### modules/network/sg.tf

Bastion:

```
resource "aws_security_group" "bastion" {
  name   = "sg_bastion-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "bastion_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "bastion_from_me_ssh" {
  type              = "ingress"
  from_port         = local.ssh_port
  to_port           = local.ssh_port
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_allowed_ssh]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_to_gitlab_ssh" {
  type                     = "egress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_to_runner_ssh" {
  type                     = "egress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.runner.id
  security_group_id        = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_to_any_http" {
  type              = "egress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_to_any_https" {
  type              = "egress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.bastion.id
}
```

Redis:

```
resource "aws_security_group" "redis" {
  name   = "sg_redis-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "redis_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "redis_from_gitlab_redis" {
  type                     = "ingress"
  from_port                = local.redis_port
  to_port                  = local.redis_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.redis.id
}
```

PostgreSQL:

```
resource "aws_security_group" "postgres" {
  name   = "sg_postgres-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "postgres_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "postgres_from_gitlab_postgresql" {
  type                     = "ingress"
  from_port                = local.postgres_port
  to_port                  = local.postgres_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.postgres.id
}
```

Internet Facing Load Balancer:

```
resource "aws_security_group" "alb_gitlab_external" {
  name   = "sg_alb_gitlab_external-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "alb_gitlab_external_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "alb_gitlab_external_from_any_http" {
  type              = "ingress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.alb_gitlab_external.id
}

resource "aws_security_group_rule" "alb_gitlab_external_to_gitlab_http" {
  type                     = "egress"
  from_port                = local.gitlab_port
  to_port                  = local.gitlab_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.alb_gitlab_external.id
}
```

Internal Load Balancer:

```
resource "aws_security_group" "alb_gitlab_internal" {
  name   = "sg_alb_gitlab_internal-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "alb_gitlab_internal_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "alb_gitlab_internal_from_runner_http" {
  type                     = "ingress"
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.runner.id
  security_group_id        = aws_security_group.alb_gitlab_internal.id
}

resource "aws_security_group_rule" "alb_gitlab_internal_to_gitlab_http" {
  type                     = "egress"
  from_port                = local.gitlab_port
  to_port                  = local.gitlab_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.alb_gitlab_internal.id
}
```

Gitlab:

```
resource "aws_security_group" "gitlab" {
  name   = "sg_gitlab-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "gitlab_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "gitlab_from_bastion_ssh" {
  type                     = "ingress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_from_alb_gitlab_external_http" {
  type                     = "ingress"
  from_port                = local.gitlab_port
  to_port                  = local.gitlab_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_gitlab_external.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_from_alb_gitlab_internal_http" {
  type                     = "ingress"
  from_port                = local.gitlab_port
  to_port                  = local.gitlab_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_gitlab_internal.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_to_any_http" {
  type              = "egress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_to_any_https" {
  type              = "egress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_to_redis_redis" {
  type                     = "egress"
  from_port                = local.redis_port
  to_port                  = local.redis_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redis.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_to_postgres_postgresql" {
  type                     = "egress"
  from_port                = local.postgres_port
  to_port                  = local.postgres_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.postgres.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_to_efs_nfs" {
  type                     = "egress"
  from_port                = local.nfs_port
  to_port                  = local.nfs_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.efs.id
  security_group_id        = aws_security_group.gitlab.id
}
```

Runner:

```
resource "aws_security_group" "runner" {
  name   = "sg_runner-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "runner_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "runner_from_bastion_ssh" {
  type                     = "ingress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.runner.id
}

resource "aws_security_group_rule" "runner_to_any_http" {
  type              = "egress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.runner.id
}

resource "aws_security_group_rule" "runner_to_any_https" {
  type              = "egress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.runner.id
}
```

EFS:

```
resource "aws_security_group" "efs" {
  name   = "sg_efs-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "efs_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "efs_from_gitlab_nfs" {
  type                     = "ingress"
  from_port                = local.nfs_port
  to_port                  = local.nfs_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.efs.id
}
```

## Building the bastion

#### modules/bastion/main.tf

I keep one and only one bastion server up and running by using an autoscaling
group in the public subnet, we don't need to have more than one bastion because
this service is not critical and we can accept an unavailability of a few of
minutes.

```
resource "aws_launch_template" "bastion" {
  name          = "bastion-${var.env}"
  image_id      = data.aws_ami.amazonlinux.id
  user_data     = base64encode(templatefile("${path.module}/user-data.sh",
                                            { eip_bastion_id = data.terraform_remote_state.network.outputs.aws_eip_bastion_id,
                                              region         = var.region }))
  instance_type = var.instance_type
  key_name      = data.terraform_remote_state.network.outputs.ssh_key

  network_interfaces {
    security_groups             = [data.terraform_remote_state.network.outputs.sg_bastion_id]
    associate_public_ip_address = true
  }

  iam_instance_profile {
    name = data.terraform_remote_state.network.outputs.iam_instance_profile_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name                 = "asg_bastion-${var.env}"
  vpc_zone_identifier  = data.terraform_remote_state.network.outputs.subnet_public_id[*]
  min_size             = 1
  max_size             = 1

  launch_template {
    id = aws_launch_template.bastion.id
  }

  tag {
    key                 = "Name"
    value               = "bastion-${var.env}"
    propagate_at_launch = true
  }
}
```

#### modules/bastion/user-data.sh

You can can check the installation process in /var/log/user-data.log, if you
experience any issues you can take a look in this file.<br />
The following script will associate the EIP defined in the network stack with
itself, that is the bastion server. Thus if the bastion experience a downtime
for any reasons and muste be re-created, it will keep the same public IP.

```
#!/usr/bin/env bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo yum -y update
sudo yum -y upgrade
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID="$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"
aws --region ${region} ec2 associate-address --instance-id $INSTANCE_ID --allocation-id ${eip_bastion_id}
```

## Building the databases

#### modules/database/main.tf

Creating the Redis service:

```
resource "aws_elasticache_subnet_group" "redis" {
  name       = "subnet-redis-${var.env}"
  subnet_ids = data.terraform_remote_state.network.outputs.subnet_private_id[*]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "cluster-redis"
  engine               = "redis"
  node_type            = var.redis_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.x"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [data.terraform_remote_state.network.outputs.sg_redis_id]
}
```

Creating the PostgreSQL service:

```
resource "aws_db_subnet_group" "postgres" {
  name       = "subnet-postgres-${var.env}"
  subnet_ids = data.terraform_remote_state.network.outputs.subnet_private_id[*]
}

resource "aws_db_instance" "postgres" {
  allocated_storage       = 5
  engine                  = "postgres"
  instance_class          = var.postgres_type
  db_name                 = "gitlabhq_production"
  username                = var.postgres_user
  password                = var.postgres_pass
  skip_final_snapshot     = true
  backup_retention_period = 0
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
  vpc_security_group_ids  = [data.terraform_remote_state.network.outputs.sg_postgres_id]
}
```

## Building the Load Balancers

#### modules/gitlab/alb.tf

The Internet Facing Load Balancer:

```
ource "aws_lb" "gitlab_external" {
  name               = "alb-gitlab-external-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.network.outputs.sg_alb_gitlab_external_id]
  subnets            = data.terraform_remote_state.network.outputs.subnet_public_id[*]
}

resource "aws_lb_target_group" "gitlab_external" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 3
    interval            = 90
    path                = "/"
    matcher             = 302
  }
}

resource "aws_lb_listener" "gitlab_external" {
  load_balancer_arn = aws_lb.gitlab_external.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.gitlab_external.arn
    type             = "forward"
  }
}
```

The internal Load Balancer:

```
resource "aws_lb" "gitlab_internal" {
  name               = "alb-gitlab-internal-${var.env}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.network.outputs.sg_alb_gitlab_internal_id]
  subnets            = data.terraform_remote_state.network.outputs.subnet_private_id[*]
}

resource "aws_lb_target_group" "gitlab_internal" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 3
    interval            = 90
    path                = "/"
    matcher             = 302
  }
}

resource "aws_lb_listener" "gitlab_internal" {
  load_balancer_arn = aws_lb.gitlab_internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.gitlab_internal.arn
    type             = "forward"
  }
}
```

## Building the Gitlab servers

#### modules/gitlab/main.tf

```
resource "aws_launch_template" "gitlab" {
  name          = "gitlab-${var.env}"
  image_id      = data.aws_ami.ubuntu.id
  user_data     = base64encode(templatefile("${path.module}/user-data.sh",
                                            { alb_dns_name     = aws_lb.gitlab_external.dns_name,
                                              gitlab_pass      = var.gitlab_pass,
                                              redis_address    = data.terraform_remote_state.database.outputs.redis_address,
                                              postgres_address = data.terraform_remote_state.database.outputs.postgres_address,
                                              postgres_user    = var.postgres_user,
                                              postgres_pass    = var.postgres_pass,
                                              efs_dns_name     = data.terraform_remote_state.network.outputs.efs_file_system_gitlab_dns_name }))
  instance_type = var.instance_type
  key_name      = data.terraform_remote_state.network.outputs.ssh_key

  block_device_mappings {
    device_name = data.aws_ami.ubuntu.root_device_name

    ebs {
      volume_size           = 10
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  network_interfaces {
    security_groups             = [data.terraform_remote_state.network.outputs.sg_gitlab_id]
    associate_public_ip_address = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "gitlab" {
  name                 = "asg_gitlab-${var.env}"
  vpc_zone_identifier  = data.terraform_remote_state.network.outputs.subnet_private_gitlab_id[*]
  target_group_arns    = [aws_lb_target_group.gitlab_external.arn, aws_lb_target_group.gitlab_internal.arn]
  health_check_type    = "ELB"
  min_size             = var.gitlab_size_desired
  max_size             = var.gitlab_size_desired

  launch_template {
    id = aws_launch_template.gitlab.id
  }

  tag {
    key                 = "Name"
    value               = "gitlab-${var.env}"
    propagate_at_launch = true
  }
}
```

The instance type is a `c5.xlarge`. The variables `min_size`and `max_size`
hold the number of Gitlab desired. By default the ec2 has a root files system to
8Gb and it was not suffisent to install Gitlab, so I set it to 10Gb.

#### modules/gitlab/user-data.sh

The following script shows you all the steps for configuring a Gitlab service:

```
#!/usr/bin/env bash

set -x -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
  curl \
  openssh-server \
  ca-certificates \
  tzdata perl \
  nfs-common
mkdir /var/opt/gitlab-nfs
echo '${efs_dns_name}:/ /var/opt/gitlab-nfs nfs4 vers=4.1,hard,rsize=1048576,wsize=1048576,timeo=600,retrans=2,noresvport 0 2' >> /etc/fstab
mount /var/opt/gitlab-nfs
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
EXTERNAL_URL="http://${alb_dns_name}" apt-get install gitlab-ee
cat << EOF >> /etc/gitlab/gitlab.rb
letsencrypt['enable'] = false

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

gitaly['configuration'] = {
  storage: [
    {
      name: 'default',
      path: '/var/opt/gitlab-nfs/gitlab-data/git-data/repositories',
    },
  ],
}
gitlab_rails['uploads_directory'] = '/var/opt/gitlab-nfs/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/var/opt/gitlab-nfs/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/var/opt/gitlab-nfs/gitlab-data/builds'
EOF

gitlab-ctl reconfigure

sudo gitlab-rake "gitlab:password:reset[root]" << EOF
${gitlab_pass}
${gitlab_pass}
EOF

[ -f /var/run/reboot-required ] && shutdown -r now
```

## Building the Gitlab Runners

#### modules/runner/main.tf

```
resource "aws_launch_template" "runner" {
  name          = "runner-${var.env}"
  image_id      = data.aws_ami.ubuntu.id
  user_data     = base64encode(templatefile("${path.module}/user-data.sh",
                                            { alb_internal_dns_name = data.terraform_remote_state.gitlab.outputs.aws_lb_gitlab_internal_dns_name,
                                              gitlab_token          = var.gitlab_token }))
  instance_type = var.instance_type
  key_name      = data.terraform_remote_state.network.outputs.ssh_key

  network_interfaces {
    security_groups             = [data.terraform_remote_state.network.outputs.sg_runner_id]
    associate_public_ip_address = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "runner" {
  name                 = "asg_runner-${var.env}"
  vpc_zone_identifier  = data.terraform_remote_state.network.outputs.subnet_private_gitlab_id[*]
  min_size             = var.runner_nb_desired
  max_size             = var.runner_nb_desired

  launch_template {
    id = aws_launch_template.runner.id
  }

  tag {
    key                 = "Name"
    value               = "runner-${var.env}"
    propagate_at_launch = true
  }
}
```

The variables `min_size`and `max_size` hold the number of Gitlab desired.

#### modules/runner/user-data.sh

The following script shows you all the steps for configuring a Runner server:

```
#!/usr/bin/env bash

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
  --docker-image "docker:29.4.1" \
  --description "docker-runner" \
  --docker-privileged \
  --docker-volumes "/certs/client"
[ -f /var/run/reboot-required ] && shutdown -r now
```

## Deploying the Gitlab infrastructure

Create a file at ~/terraform/aws-terraform-gitlab/terraform_vars_dev_secrets:

```
export TF_VAR_aws_profile="dev"
export TF_VAR_region="eu-west-3"
export TF_VAR_bucket="XXXX-tofu-state"
export TF_VAR_key_network="gitlab/dev/network/terraform.tfstate"
export TF_VAR_key_bastion="gitlab/dev/bastion/terraform.tfstate"
export TF_VAR_key_database="gitlab/dev/database/terraform.tfstate"
export TF_VAR_key_gitlab="gitlab/dev/gitlab/terraform.tfstate"
export TF_VAR_key_runner="gitlab/dev/runner/terraform.tfstate"
export TF_VAR_postgres_user="gitlab"
export TF_VAR_postgres_pass="XXXX"
export TF_VAR_gitlab_pass="XXXX"
export TF_VAR_ssh_public_key="ssh-ed25519 XXXX"
MY_IP=$(curl -s ifconfig.co/)
export TF_VAR_my_ip_address="$MY_IP/32"
```

Perform the following commands for building the infrastructure:

    $ cd envs/dev/01-network
    $ make apply
    $ cd ../02-bastion
    $ make apply
    $ cd ../03-database
    $ make apply
    $ cd ../04-gitlab
    $ make apply

You can access the Gitlab server for checking the log:

    $ ssh -J ec2-user@<BASTION_IP> ubuntu@<GITLAB_IP> tail -f /var/log/user-data.log

When Gitlab has finished to be installed, you can open your browser and point
it to the public Load Balancer name, you can now log in with the root user
and the password you set by using the TF_VAR_gitlab_pass variable.

If you want to use runners for leveraging the CI/CD of Gitlab, go to the
"Admin Area" ->  "CI/CD" -> "Runners", create a runner then get the registration
token. Now let's build a runner by providing this token:

    $ cd ../05-runner
    $ make apply

Wait for a while, then you will see a runner is registred to the Gitlab server.

## Destroying your infrastructure

After finishing your test, destroy your infrastructure:

    $ cd envs/dev/05-runner
    $ make destroy
    $ cd ../04-gitlab
    $ make destroy
    $ cd ../03-database
    $ make destroy
    $ cd ../02-bastion
    $ make destroy
    $ cd ../01-network
    $ make destroy

## Summary

This example gave you an overview of the power of AWS and OpenTofu, if you
have managed to build and understand this exercise, I say to you congrats!
In the next tutorial, I will show you how to build a vanilla kubernetes on
AWS using OpenTofu.
