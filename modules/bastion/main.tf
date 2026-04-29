data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    profile = var.aws_profile
    bucket  = var.network_remote_state_bucket
    key     = var.network_remote_state_key
    region  = var.region
  }
}

data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [137112412989] # amazon owner id
}

resource "aws_launch_template" "bastion" {
  name          = "bastion-${var.env}"
  image_id      = data.aws_ami.amazonlinux.id
  user_data     = base64encode(templatefile("${path.module}/user-data.sh",
                                            { eip_bastion_id = data.terraform_remote_state.network.outputs.aws_eip_bastion_id,
                                              region         = var.region }))
  instance_type = var.instance_type
  key_name      = data.terraform_remote_state.network.outputs.ssh_key

  network_interfaces {
    security_groups             = [data.terraform_remote_state.network.outputs.sg_bastion_id]
    associate_public_ip_address = true
  }

  iam_instance_profile {
    name = data.terraform_remote_state.network.outputs.iam_instance_profile_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name                 = "asg_bastion-${var.env}"
  vpc_zone_identifier  = data.terraform_remote_state.network.outputs.subnet_public_id[*]
  min_size             = 1
  max_size             = 1

  launch_template {
    id = aws_launch_template.bastion.id
  }

  tag {
    key                 = "Name"
    value               = "bastion-${var.env}"
    propagate_at_launch = true
  }
}
