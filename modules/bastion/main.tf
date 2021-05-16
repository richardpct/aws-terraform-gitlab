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

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    eip_bastion_id = data.terraform_remote_state.base.outputs.aws_eip_bastion_id
  }
}

resource "aws_launch_configuration" "bastion" {
  name                        = "bastion-${var.env}"
  image_id                    = var.image_id
  user_data                   = data.template_file.user_data.rendered
  instance_type               = var.instance_type
  key_name                    = data.terraform_remote_state.base.outputs.ssh_key
  security_groups             = [data.terraform_remote_state.base.outputs.sg_bastion_id]
  iam_instance_profile        = data.terraform_remote_state.base.outputs.iam_instance_profile_name
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name                 = "asg_bastion-${var.env}"
  launch_configuration = aws_launch_configuration.bastion.id
  vpc_zone_identifier  = [data.terraform_remote_state.base.outputs.subnet_public_a_id, data.terraform_remote_state.base.outputs.subnet_public_b_id]
  min_size             = 1
  max_size             = 1

  tag {
    key                 = "Name"
    value               = "bastion-${var.env}"
    propagate_at_launch = true
  }
}
