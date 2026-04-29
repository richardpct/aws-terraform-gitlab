data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    profile = var.aws_profile
    bucket  = var.network_remote_state_bucket
    key     = var.network_remote_state_key
    region  = var.region
  }
}

data "terraform_remote_state" "gitlab" {
  backend = "s3"

  config = {
    profile = var.aws_profile
    bucket  = var.gitlab_remote_state_bucket
    key     = var.gitlab_remote_state_key
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

resource "aws_launch_template" "runner" {
  name          = "runner-${var.env}"
  image_id      = data.aws_ami.ubuntu.id
  user_data     = base64encode(templatefile("${path.module}/user-data.sh",
                                            { alb_internal_dns_name = data.terraform_remote_state.gitlab.outputs.aws_lb_gitlab_internal_dns_name,
                                              gitlab_token          = var.gitlab_token }))
  instance_type = var.instance_type
  key_name      = data.terraform_remote_state.network.outputs.ssh_key

  network_interfaces {
    security_groups             = [data.terraform_remote_state.network.outputs.sg_runner_id]
    associate_public_ip_address = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "runner" {
  name                 = "asg_runner-${var.env}"
  vpc_zone_identifier  = data.terraform_remote_state.network.outputs.subnet_private_gitlab_id[*]
  min_size             = var.runner_nb_desired
  max_size             = var.runner_nb_desired

  launch_template {
    id = aws_launch_template.runner.id
  }

  tag {
    key                 = "Name"
    value               = "runner-${var.env}"
    propagate_at_launch = true
  }
}
