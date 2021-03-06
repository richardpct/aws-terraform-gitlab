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

output "subnet_private_a_id" {
  value = module.base.subnet_private_a_id
}

output "subnet_private_b_id" {
  value = module.base.subnet_private_b_id
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

output "sg_alb_gitlab_public_id" {
  value = module.base.sg_alb_gitlab_public_id
}

output "sg_alb_gitlab_internal_id" {
  value = module.base.sg_alb_gitlab_internal_id
}

output "sg_runner_id" {
  value = module.base.sg_runner_id
}

output "aws_eip_bastion_id" {
  value = module.base.aws_eip_bastion_id
}

output "efs_file_system_gitlab_dns_name" {
  value = module.base.efs_file_system_gitlab_dns_name
}

output "iam_instance_profile_name" {
  value = module.base.iam_instance_profile_name
}

output "ssh_key" {
  value = module.base.ssh_key
}
