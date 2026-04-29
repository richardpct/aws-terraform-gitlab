# rules for bastion
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

# rules for redis
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

# rules for postgresql
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

# rules for alb gitlab external
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

# rules for alb gitlab internal
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

# rules for gitlab
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

# rules for runner
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

# rules for efs
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
