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

data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket = var.database_remote_state_bucket
    key    = var.database_remote_state_key
    region = var.region
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    alb_dns_name     = aws_lb.web.dns_name
    gitlab_pass      = var.gitlab_pass
    redis_address    = data.terraform_remote_state.database.outputs.redis_address
    postgres_address = data.terraform_remote_state.database.outputs.postgres_address
    postgres_user    = var.postgres_user
    postgres_pass    = var.postgres_pass
    efs_dns_name     = data.terraform_remote_state.base.outputs.efs_file_system_gitlab_dns_name
  }
}

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
  vpc_zone_identifier  = [data.terraform_remote_state.base.outputs.subnet_private_gitlab_a_id, data.terraform_remote_state.base.outputs.subnet_private_gitlab_b_id]
  target_group_arns    = [aws_lb_target_group.web.arn, aws_lb_target_group.web_internal.arn]
  health_check_type    = "ELB"

  min_size             = 1
  max_size             = 1

  tag {
    key                 = "Name"
    value               = "gitlab-${var.env}"
    propagate_at_launch = true
  }
}
