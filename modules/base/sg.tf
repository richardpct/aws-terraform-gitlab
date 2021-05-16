# Rules for Bastion
resource "aws_security_group" "bastion" {
  name   = "sg_bastion-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "bastion_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "bastion_inbound_ssh" {
  type              = "ingress"
  from_port         = local.ssh_port
  to_port           = local.ssh_port
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_allowed_ssh]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_outbound_ssh" {
  type              = "egress"
  from_port         = local.ssh_port
  to_port           = local.ssh_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_outbound_http" {
  type              = "egress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_outbound_https" {
  type              = "egress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.bastion.id
}

# Rules for Redis
resource "aws_security_group" "redis" {
  name   = "sg_redis-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "redis_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "redis_inbound_gitlab" {
  type                     = "ingress"
  from_port                = local.redis_port
  to_port                  = local.redis_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.redis.id
}

# Rules for PostgreSQL
resource "aws_security_group" "postgres" {
  name   = "sg_postgres-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "postgres_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "postgres_inbound_gitlab" {
  type                     = "ingress"
  from_port                = local.postgres_port
  to_port                  = local.postgres_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.postgres.id
}

# Rules for alb web
resource "aws_security_group" "alb_web" {
  name   = "sg_alb_web-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "alb_web_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "alb_web_inbound_http" {
  type              = "ingress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.alb_web.id
}

resource "aws_security_group_rule" "alb_web_outbound_http" {
  type                     = "egress"
  from_port                = local.webserver_port
  to_port                  = local.webserver_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.alb_web.id
}

# Rules for Gitlab
resource "aws_security_group" "gitlab" {
  name   = "sg_gitlab-${var.env}"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "gitlab_sg-${var.env}"
  }
}

resource "aws_security_group_rule" "gitlab_inbound_ssh" {
  type                     = "ingress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_inbound_http" {
  type                     = "ingress"
  from_port                = local.webserver_port
  to_port                  = local.webserver_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_web.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_outbound_http" {
  type              = "egress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_outbound_https" {
  type              = "egress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = local.anywhere
  security_group_id = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_outbound_redis" {
  type                     = "egress"
  from_port                = local.redis_port
  to_port                  = local.redis_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redis.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_outbound_postgres" {
  type                     = "egress"
  from_port                = local.postgres_port
  to_port                  = local.postgres_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.postgres.id
  security_group_id        = aws_security_group.gitlab.id
}
