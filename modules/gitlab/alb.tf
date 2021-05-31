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
