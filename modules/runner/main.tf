provider "aws" {
  region = var.region
}

data "terraform_remote_state" "base" {
  backend = "s3"

  config = {
    bucket = var.base_remote_state_bucket
    key    = var.base_remote_state_key
    region = var.region
  }
}

data "terraform_remote_state" "webserver" {
  backend = "s3"

  config = {
    bucket = var.webserver_remote_state_bucket
    key    = var.webserver_remote_state_key
    region = var.region
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    alb_internal_dns_name = data.terraform_remote_state.webserver.outputs.aws_lb_web_internal_dns_name
    gitlab_token          = var.gitlab_token
  }
}

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
  vpc_zone_identifier  = [data.terraform_remote_state.base.outputs.subnet_private_gitlab_a_id, data.terraform_remote_state.base.outputs.subnet_private_gitlab_b_id]
  min_size             = 1
  max_size             = 1

  tag {
    key                 = "Name"
    value               = "runner-${var.env}"
    propagate_at_launch = true
  }
}
