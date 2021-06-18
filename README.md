## Table of Contents
1. [Purpose](#Purpose)
2. [Configuring the network](#Configuring the network)
3. [Creating the EFS](#Creating the EFS)
4. [Configuring the firewall rules](#Configuring the firewall rules)
5. [Building the bastion](#Building the bastion)
6. [Building the databases](#Building the databases)
7. [Building the Load Balancers](#Building the Load Balancers)
8. [Building the Gitlab servers](#Building the Gitlab servers)
9. [Building the Gitlab Runners](#Building the Gitlab Runners)
10. [Deploying the Gitlab infrastructure](#Deploying the Gitlab infrastructure)
11. [Destroying your infrastructure](#Destroying your infrastructure)
12. [Summary](#Summary)

<a name="Purpose"></a>
## Purpose

This tutorial is intended to show you how to build Gitlab on AWS automated with
Terraform, the source code can be found [here](https://github.com/richardpct/aws-terraform-gitlab).

The following figure depicts the infrastructure that you will build:

<img src="https://raw.githubusercontent.com/richardpct/images/master/aws-tuto-gitlab/image01.png">

Gitlab is one of the most used Git repository manager in Open Source, in
addition you may use the CI/CD feature called `Runners`.<br />
For building the Gitlab infrastructure I have followed the official Gitlab
installation that you can found [here](https://docs.gitlab.com/ee/install/aws/),
except I don't use a separate Gitaly service for managing the Git repositories,
instead of this I prefer use a shared NFS because I think it is a good
trade-off between maintenance and cost.

<a name="Configuring the network"></a>
## Configuring the network

#### environments/dev/00-base/main.tf

The following code shows how the network is split into subnets:

```
module "base" {
  source = "../../../modules/base"

  region                  = "eu-west-3"
  env                     = "dev"
  vpc_cidr_block          = "10.0.0.0/16"
  subnet_public_a         = "10.0.0.0/24"
  subnet_public_b         = "10.0.1.0/24"
  subnet_private_gitlab_a = "10.0.2.0/24"
  subnet_private_gitlab_b = "10.0.3.0/24"
  subnet_private_a        = "10.0.4.0/24"
  subnet_private_b        = "10.0.5.0/24"
  cidr_allowed_ssh        = var.my_ip_address
  ssh_public_key          = var.ssh_public_key
}
```

The subnets are organized as follows:

  - Public subnet:
    - The bastion server is the one that allows you to connect via ssh to the
Gitlab server and Runner
    - The NAT Gateway allows the services included in the private subnet
(Gitlab and Runner) to access the Internet
    - The public Load Balancer will forward the client requests to the Gitlab
server
  - Private Gitlab subnet (with access to Internet):
    - The Gitlab servers and the Runners need to reach the Internet in order to
fetch and upgrade packages
  - Private subnet (No access to Internet):
    - The PostgreSQL and Redis databases
    - The internal Load Balancer allows the runner to reach the Gitlab server
    - The EFS stores all Gitlab datas

#### modules/base/network.tf

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

I remind you that the Internet Gateway is used so that the Internet can reach
any private subnet associated with this Gateway.

  - Creating all subnets:

```
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_public_a
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "subnet_public_a-${var.env}"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_public_b
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "subnet_public_b-${var.env}"
  }
}

resource "aws_subnet" "private_gitlab_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private_gitlab_a
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "subnet_private_gitlab_a-${var.env}"
  }
}

resource "aws_subnet" "private_gitlab_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private_gitlab_b
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "subnet_private_gitlab_b-${var.env}"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private_a
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "subnet_private_a-${var.env}"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private_b
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "subnet_private_b-${var.env}"
  }
}
```

As you can see, all subnets are created into 2 availability zones, thus if an
outage occurs in a entire data center, the entire service will run into the
other availability zone.

  - Creating the NAT Gateway:

```
resource "aws_eip" "nat_a" {
  vpc = true

  tags = {
    Name = "eip_nat_a-${var.env}"
  }
}

resource "aws_eip" "nat_b" {
  vpc = true

  tags = {
    Name = "eip_nat_b-${var.env}"
  }
}

resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "nat_gw_a-${var.env}"
  }
}

resource "aws_nat_gateway" "nat_gw_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name = "nat_gw_b-${var.env}"
  }
}
```

I remind you that the Nat Gateway is used so that the public subnet can reach
the Internet.

  - Creating the route tables:

```
resource "aws_route_table" "route_nat_a" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_a.id
  }

  tags = {
    Name = "default_route_a-${var.env}"
  }
}

resource "aws_route_table" "route_nat_b" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_b.id
  }

  tags = {
    Name = "default_route_b-${var.env}"
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

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "private_gitlab_a" {
  subnet_id      = aws_subnet.private_gitlab_a.id
  route_table_id = aws_route_table.route_nat_a.id
}

resource "aws_route_table_association" "private_gitlab_b" {
  subnet_id      = aws_subnet.private_gitlab_b.id
  route_table_id = aws_route_table.route_nat_b.id
}
```

  - Creating the EIP for the bastion server:

```
resource "aws_eip" "bastion" {
  vpc = true

  tags = {
    Name = "eip_bastion-${var.env}"
  }
}
```

<a name="Creating the EFS"></a>
## Creating the EFS

#### environments/dev/00-base/efs.tf

```
resource "aws_efs_file_system" "gitlab" {
  tags = {
    Name = "gitlab-efs"
  }
}

resource "aws_efs_mount_target" "mount_target_a" {
  file_system_id  = aws_efs_file_system.gitlab.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "mount_target_b" {
  file_system_id  = aws_efs_file_system.gitlab.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs.id]
}
```

<a name="Configuring the firewall rules"></a>
## Configuring the firewall rules

#### modules/base/sg.tf

Bastion:

```
# Rules for Bastion
resource "aws_security_group" "bastion" {
  name   = "sg_bastion-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "bastion_sg-${var.env}"
  }
}

# We can access the bastion from our own IP address
resource "aws_security_group_rule" "bastion_inbound_ssh" {
  type              = "ingress"
  from_port         = local.ssh_port
  to_port           = local.ssh_port
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_allowed_ssh]
  security_group_id = aws_security_group.bastion.id
}

# The bastion can access all the servers inside our infrastructure through SSH
resource "aws_security_group_rule" "bastion_outbound_ssh" {
  type              = "egress"
  from_port         = local.ssh_port
  to_port           = local.ssh_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.bastion.id
}

# The bastion can upgrade their packages from the Internet
resource "aws_security_group_rule" "bastion_outbound_http" {
  type              = "egress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.bastion.id
}

# The bastion can upgrade their packages from the Internet
resource "aws_security_group_rule" "bastion_outbound_https" {
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
# Rules for Redis
resource "aws_security_group" "redis" {
  name   = "sg_redis-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "redis_sg-${var.env}"
  }
}

# The Gitlab server can perform requests to the Redis server
resource "aws_security_group_rule" "redis_inbound_gitlab" {
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
# Rules for PostgreSQL
resource "aws_security_group" "postgres" {
  name   = "sg_postgres-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "postgres_sg-${var.env}"
  }
}

# The Gitlab server can perform requests to the PostgreSQL server
resource "aws_security_group_rule" "postgres_inbound_gitlab" {
  type                     = "ingress"
  from_port                = local.postgres_port
  to_port                  = local.postgres_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.postgres.id
}
```

Public Load Balancer:

```
# Rules for alb gitlab public
resource "aws_security_group" "alb_gitlab_public" {
  name   = "sg_alb_gitlab_public-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "alb_gitlab_public_sg-${var.env}"
  }
}

# The public Load Balancer can accept HTTP requests from the Internet 
resource "aws_security_group_rule" "alb_gitlab_public_inbound_http" {
  type              = "ingress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.alb_gitlab_public.id
}

# The public Load Balancer can forward HTTP requests from Internet to the Gitalb servers
resource "aws_security_group_rule" "alb_gitlab_public_outbound_http" {
  type                     = "egress"
  from_port                = local.gitlab_port
  to_port                  = local.gitlab_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.alb_gitlab_public.id
}
```

Internal Load Balancer:

```
# Rules for alb gitlab internal
resource "aws_security_group" "alb_gitlab_internal" {
  name   = "sg_alb_gitlab_internal-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "alb_gitlab_internal_sg-${var.env}"
  }
}

# The Runners can access the Internal Load Balancer
resource "aws_security_group_rule" "alb_gitlab_internal_inbound_http" {
  type                     = "ingress"
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.runner.id
  security_group_id        = aws_security_group.alb_gitlab_internal.id
}

# The Internal Load Balancer can forward requests to the Gitlab servers
resource "aws_security_group_rule" "alb_gitlab_internal_outbound_http" {
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
# Rules for Gitlab
resource "aws_security_group" "gitlab" {
  name   = "sg_gitlab-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "gitlab_sg-${var.env}"
  }
}

# The bastion can access the Gitlab servers
resource "aws_security_group_rule" "gitlab_inbound_ssh" {
  type                     = "ingress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.gitlab.id
}

# The public Load Balancer can forward requests from the Internet to the Gitlab servers
resource "aws_security_group_rule" "gitlab_inbound_http" {
  type                     = "ingress"
  from_port                = local.gitlab_port
  to_port                  = local.gitlab_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_gitlab_public.id
  security_group_id        = aws_security_group.gitlab.id
}

# The internal Load Balancer can forward requests to the Gitlab servers
resource "aws_security_group_rule" "gitlab_inbound_http_internal" {
  type                     = "ingress"
  from_port                = local.gitlab_port
  to_port                  = local.gitlab_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_gitlab_internal.id
  security_group_id        = aws_security_group.gitlab.id
}

# The Gitlab server can make HTTP requests to the Internet
resource "aws_security_group_rule" "gitlab_outbound_http" {
  type              = "egress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.gitlab.id
}

# The Gitlab server can make requests HTTPS to the Internet
resource "aws_security_group_rule" "gitlab_outbound_https" {
  type              = "egress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.gitlab.id
}

# The Gitlab servers can make requests to the Redis server
resource "aws_security_group_rule" "gitlab_outbound_redis" {
  type                     = "egress"
  from_port                = local.redis_port
  to_port                  = local.redis_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redis.id
  security_group_id        = aws_security_group.gitlab.id
}

# The Gitlab servers can make requests to the PostgreSQL server
resource "aws_security_group_rule" "gitlab_outbound_postgres" {
  type                     = "egress"
  from_port                = local.postgres_port
  to_port                  = local.postgres_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.postgres.id
  security_group_id        = aws_security_group.gitlab.id
}

# The Gitlab servers can access the EFS
resource "aws_security_group_rule" "gitlab_outbound_efs" {
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
# Rules for Runner
resource "aws_security_group" "runner" {
  name   = "sg_runner-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "runner_sg-${var.env}"
  }
}

# We can access the runner servers from the bastion through SSH
resource "aws_security_group_rule" "runner_inbound_ssh" {
  type                     = "ingress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.runner.id
}

# The runner servers can reach the Internet through HTTP
resource "aws_security_group_rule" "runner_outbound_http" {
  type              = "egress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.runner.id
}

# The runner can reach the Internet through HTTPS
resource "aws_security_group_rule" "runner_outbound_https" {
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
# Rules for EFS
resource "aws_security_group" "efs" {
  name   = "sg_efs-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "efs_sg-${var.env}"
  }
}

# The Gitlab servers can access the EFS
resource "aws_security_group_rule" "efs_inbound_gitlab" {
  type                     = "ingress"
  from_port                = local.nfs_port
  to_port                  = local.nfs_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.efs.id
}
```

<a name="Building the bastion"></a>
## Building the bastion

#### modules/bastion/main.tf

I keep one and only one bastion server up and running by using an autoscaling
group in the public subnet:

```
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    eip_bastion_id = data.terraform_remote_state.base.outputs.aws_eip_bastion_id
  }
}

resource "aws_launch_configuration" "bastion" {
  name                        = "bastion-${var.env}"
  image_id                    = var.image_id
  user_data                   = data.template_file.user_data.rendered
  instance_type               = var.instance_type
  key_name                    = data.terraform_remote_state.base.outputs.ssh_key
  security_groups             = [data.terraform_remote_state.base.outputs.sg_bastion_id]
  iam_instance_profile        = data.terraform_remote_state.base.outputs.iam_instance_profile_name
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name                 = "asg_bastion-${var.env}"
  launch_configuration = aws_launch_configuration.bastion.id
  vpc_zone_identifier  = [data.terraform_remote_state.base.outputs.subnet_public_a_id, data.terraform_remote_state.base.outputs.subnet_public_b_id]
  min_size             = 1
  max_size             = 1

  tag {
    key                 = "Name"
    value               = "bastion-${var.env}"
    propagate_at_launch = true
  }
}
```

#### modules/bastion/user-data.sh

You can follow the installation process in /var/log/user-data.log, if you
experience any issues you can take a look in this file.<br />
The following script will associate the EIP defined in the base stack with
itself, that is the bastion server. Thus if the bastion experience a downtime
for any reasons, it will keep the same public IP.

```
#!/bin/bash

set -x

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo yum -y update
INSTANCE_ID="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
aws --region eu-west-3 ec2 associate-address --instance-id $INSTANCE_ID --allocation-id ${eip_bastion_id}
```

<a name="Building the databases"></a>
## Building the databases

#### modules/database/main.tf

Creating the Redis service:

```
resource "aws_elasticache_subnet_group" "redis" {
  name       = "subnet-redis-${var.env}"
  subnet_ids = [data.terraform_remote_state.base.outputs.subnet_private_a_id, data.terraform_remote_state.base.outputs.subnet_private_b_id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "cluster-redis"
  engine               = "redis"
  node_type            = var.redis_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [data.terraform_remote_state.base.outputs.sg_redis_id]
}
```

Creating the PostgreSQL service:

```
resource "aws_db_subnet_group" "postgres" {
  name       = "subnet-postgres-${var.env}"
  subnet_ids = [data.terraform_remote_state.base.outputs.subnet_private_a_id, data.terraform_remote_state.base.outputs.subnet_private_b_id]
}

resource "aws_db_instance" "postgres" {
  allocated_storage       = 5
  engine                  = "postgres"
  instance_class          = var.postgres_type
  name                    = "gitlabhq_production"
  username                = var.postgres_user
  password                = var.postgres_pass
  skip_final_snapshot     = true
  backup_retention_period = 0
  vpc_security_group_ids  = [data.terraform_remote_state.base.outputs.sg_postgres_id]
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
}
```

<a name="Building the Load Balancers"></a>
## Building the Load Balancers

#### modules/gitlab/alb.tf

The public Load Balancer:

```
resource "aws_lb" "gitlab_public" {
  name               = "alb-gitlab-public-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.base.outputs.sg_alb_gitlab_public_id]
  subnets            = [data.terraform_remote_state.base.outputs.subnet_public_a_id, data.terraform_remote_state.base.outputs.subnet_public_b_id]
}

resource "aws_lb_target_group" "gitlab_public" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.base.outputs.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 3
    interval            = 90
    path                = "/"
    matcher             = 302
  }
}

resource "aws_lb_listener" "gitlab_public" {
  load_balancer_arn = aws_lb.gitlab_public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.gitlab_public.arn
    type             = "forward"
  }
}
```

The private Load Balancer:

```
resource "aws_lb" "gitlab_internal" {
  name               = "alb-gitlab-internal-${var.env}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.base.outputs.sg_alb_gitlab_internal_id]
  subnets            = [data.terraform_remote_state.base.outputs.subnet_private_a_id, data.terraform_remote_state.base.outputs.subnet_private_b_id]
}

resource "aws_lb_target_group" "gitlab_internal" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.base.outputs.vpc_id

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

<a name="Building the Gitlab servers"></a>
## Building the Gitlab servers

#### modules/gitlab/main.tf

```
resource "aws_launch_configuration" "gitlab" {
  name                        = "gitlab-${var.env}"
  image_id                    = var.image_id
  user_data                   = data.template_file.user_data.rendered
  instance_type               = var.instance_type
  key_name                    = data.terraform_remote_state.base.outputs.ssh_key
  security_groups             = [data.terraform_remote_state.base.outputs.sg_gitlab_id]
  iam_instance_profile        = data.terraform_remote_state.base.outputs.iam_instance_profile_name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "gitlab" {
  name                 = "asg_gitlab-${var.env}"
  launch_configuration = aws_launch_configuration.gitlab.id
  vpc_zone_identifier  = [data.terraform_remote_state.base.outputs.subnet_private_gitlab_a_id, data.terraform_remote_state.base.outputs.subnet_private_gitlab_
b_id]
  target_group_arns    = [aws_lb_target_group.gitlab_public.arn, aws_lb_target_group.gitlab_internal.arn]
  health_check_type    = "ELB"

  min_size             = var.gitlab_size_desired
  max_size             = var.gitlab_size_desired

  tag {
    key                 = "Name"
    value               = "gitlab-${var.env}"
    propagate_at_launch = true
  }
}
```

The instance type is a `c5.xlarge`. The variables `min_size`and `max_size`
hold the number of Gitlab desired.

#### modules/gitlab/user-data.sh

The following script shows you all the steps for configuring a Gitlab service:

```
#!/bin/bash

set -x

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
```

<a name="Building the Gitlab Runners"></a>
## Building the Gitlab Runners

#### modules/runner/main.tf

```
resource "aws_launch_configuration" "runner" {
  name                        = "runner-${var.env}"
  image_id                    = var.image_id
  user_data                   = data.template_file.user_data.rendered
  instance_type               = var.instance_type
  key_name                    = data.terraform_remote_state.base.outputs.ssh_key
  security_groups             = [data.terraform_remote_state.base.outputs.sg_runner_id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "runner" {
  name                 = "asg_runner-${var.env}"
  launch_configuration = aws_launch_configuration.runner.id
  vpc_zone_identifier  = [data.terraform_remote_state.base.outputs.subnet_private_gitlab_a_id, data.terraform_remote_state.base.outputs.subnet_private_gitlab_
b_id]
  min_size             = var.runner_nb_desired
  max_size             = var.runner_nb_desired

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
```

<a name="Deploying the Gitlab infrastructure"></a>
## Deploying the Gitlab infrastructure

Export the following environment variables:

    $ export TF_VAR_region="eu-west-3"
    $ export TF_VAR_bucket="yourbucket-terraform-state"
    $ export TF_VAR_dev_base_key="terraform/dev/base/terraform.tfstate"
    $ export TF_VAR_dev_bastion_key="terraform/dev/bastion/terraform.tfstate"
    $ export TF_VAR_dev_database_key="terraform/dev/database/terraform.tfstate"
    $ export TF_VAR_dev_gitlab_key="terraform/dev/gitlab/terraform.tfstate"
    $ export TF_VAR_dev_runner_key="terraform/dev/runner/terraform.tfstate"
    $ export TF_VAR_dev_postgres_user="gitlab"
    $ export TF_VAR_dev_postgres_pass="XXXXXXXX"
    $ export TF_VAR_dev_gitlab_pass="XXXXXXXX"
    $ export TF_VAR_ssh_public_key="ssh-rsa XXXXXXXX..."
    $ export TF_VAR_my_ip_address=$(curl -s 'https://duckduckgo.com/?q=ip&t=h_&ia=answer' \
    | sed -e 's/.*Your IP address is \([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\) in.*/\1/')

Perform the following commands for building the infrastructure:

    $ cd environments/dev
    $ cd 00-network
    $ terraform init \
        -backend-config="bucket=${TF_VAR_bucket}" \
        -backend-config="key=${TF_VAR_dev_network_key}" \
        -backend-config="region=${TF_VAR_region}"
    $ terraform apply
    $ cd ../01-bastion
    $ terraform init \
        -backend-config="bucket=${TF_VAR_bucket}" \
        -backend-config="key=${TF_VAR_dev_bastion_key}" \
        -backend-config="region=${TF_VAR_region}"
    $ terraform apply
    $ cd ../02-database
    $ terraform init \
        -backend-config="bucket=${TF_VAR_bucket}" \
        -backend-config="key=${TF_VAR_dev_database_key}" \
        -backend-config="region=${TF_VAR_region}"
    $ terraform apply
    $ cd ../03-gitlab
    $ terraform init \
        -backend-config="bucket=${TF_VAR_bucket}" \
        -backend-config="key=${TF_VAR_dev_gitlab_key}" \
        -backend-config="region=${TF_VAR_region}"
    $ terraform apply

You can access the Gitlab server for checking the log:

    $ ssh -J ec2-user@IP_bastion centos@IP_Gitlab
    $ tail -f /var/log/user-data.log

When Gitlab has finished to be installed, you can open your browser and point
it to the public Load Balancer name, then you will be asked to set your
password. You can now log in with the root user with its password.

If you want to use runners for leveraging the CI/CD of Gitlab, go to the
"Admin Area" then "Runners", get the registration token. Now let's build a
runner by providing the token:

    $ cd ../04-runner
    $ terraform init \
        -backend-config="bucket=${TF_VAR_bucket}" \
        -backend-config="key=${TF_VAR_dev_runner_key}" \
        -backend-config="region=${TF_VAR_region}"
    $ terraform apply

Wait for a while, then you would see a runner is registred to the Gitlab server.

You need to perform `terraform init` once.

If you want to increase the number of Gitlab servers or runners, run the
following command:

    $ terraform apply -var="gitlab_nb_desired=2"
    $ terraform apply -var="runner_nb_desired=2"

<a name="Destroying your infrastructure"></a>
## Destroying your infrastructure

After finishing your test, destroy your infrastructure:

    $ cd environments/dev
    $ cd 04-runner
    $ terraform destroy
    $ cd ../03-gitlab
    $ terraform destroy
    $ cd ../02-database
    $ terraform destroy
    $ cd ../01-bastion
    $ terraform destroy
    $ cd ../00-network
    $ terraform destroy

<a name="Summary"></a>
## Summary

This example gave you an overview of the power of AWS and Terraform, if you
have managed to build and understand this exercise, I say to you congrats!
