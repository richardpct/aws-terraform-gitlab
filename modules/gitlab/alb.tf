resource "aws_lb" "web" {
  name               = "alb-web-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.base.outputs.sg_alb_web_id]
  subnets            = [data.terraform_remote_state.base.outputs.subnet_public_a_id, data.terraform_remote_state.base.outputs.subnet_public_b_id]
}

resource "aws_lb_target_group" "web" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.base.outputs.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 3
    interval            = 180
    path                = "/"
    matcher             = 302
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.web.arn
    type             = "forward"
  }
}

resource "aws_lb" "web_internal" {
  name               = "alb-web-internal-${var.env}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.base.outputs.sg_alb_web_internal_id]
  subnets            = [data.terraform_remote_state.base.outputs.subnet_public_a_id, data.terraform_remote_state.base.outputs.subnet_public_b_id]
}

resource "aws_lb_target_group" "web_internal" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.base.outputs.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 3
    interval            = 180
    path                = "/"
    matcher             = 302
  }
}

resource "aws_lb_listener" "web_internal" {
  load_balancer_arn = aws_lb.web_internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.web_internal.arn
    type             = "forward"
  }
}
