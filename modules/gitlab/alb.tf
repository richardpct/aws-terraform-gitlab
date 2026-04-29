resource "aws_lb" "gitlab_external" {
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
