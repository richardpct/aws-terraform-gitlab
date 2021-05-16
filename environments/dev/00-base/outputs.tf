output "vpc_id" {
  value = module.base.vpc_id
}

output "subnet_public_a_id" {
  value = module.base.subnet_public_a_id
}

output "subnet_public_b_id" {
  value = module.base.subnet_public_b_id
}

output "subnet_private_gitlab_a_id" {
  value = module.base.subnet_private_gitlab_a_id
}

output "subnet_private_gitlab_b_id" {
  value = module.base.subnet_private_gitlab_b_id
}

output "subnet_private_db_a_id" {
  value = module.base.subnet_private_db_a_id
}

output "subnet_private_db_b_id" {
  value = module.base.subnet_private_db_b_id
}

output "sg_bastion_id" {
  value = module.base.sg_bastion_id
}

output "sg_redis_id" {
  value = module.base.sg_redis_id
}

output "sg_postgres_id" {
  value = module.base.sg_postgres_id
}

output "sg_gitlab_id" {
  value = module.base.sg_gitlab_id
}

output "sg_alb_web_id" {
  value = module.base.sg_alb_web_id
}

output "aws_eip_bastion_id" {
  value = module.base.aws_eip_bastion_id
}

output "iam_instance_profile_name" {
  value = module.base.iam_instance_profile_name
}

output "ssh_key" {
  value = module.base.ssh_key
}
