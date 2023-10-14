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

data "terraform_remote_state" "gitlab" {
  backend = "s3"

  config = {
    bucket = var.gitlab_remote_state_bucket
    key    = var.gitlab_remote_state_key
    region = var.region
  }
}

resource "aws_launch_configuration" "runner" {
  name            = "runner-${var.env}"
  image_id        = var.image_id
  user_data       = templatefile("${path.module}/user-data.sh",
                                 { alb_internal_dns_name = data.terraform_remote_state.gitlab.outputs.aws_lb_gitlab_internal_dns_name,
                                   gitlab_token          = var.gitlab_token })
  instance_type   = var.instance_type
  key_name        = data.terraform_remote_state.base.outputs.ssh_key
  security_groups = [data.terraform_remote_state.base.outputs.sg_runner_id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "runner" {
  name                 = "asg_runner-${var.env}"
  launch_configuration = aws_launch_configuration.runner.id
  vpc_zone_identifier  = [data.terraform_remote_state.base.outputs.subnet_private_gitlab_a_id, data.terraform_remote_state.base.outputs.subnet_private_gitlab_b_id]
  min_size             = var.runner_nb_desired
  max_size             = var.runner_nb_desired

  tag {
    key                 = "Name"
    value               = "runner-${var.env}"
    propagate_at_launch = true
  }
}
