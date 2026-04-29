data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    profile = var.aws_profile
    bucket  = var.network_remote_state_bucket
    key     = var.network_remote_state_key
    region  = var.region
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    profile = var.aws_profile
    bucket  = var.database_remote_state_bucket
    key     = var.database_remote_state_key
    region  = var.region
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-minimal-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # ubuntu owner id
}

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
