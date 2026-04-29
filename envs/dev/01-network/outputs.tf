output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_public_id" {
  value = module.network.subnet_public_id
}

output "subnet_private_gitlab_id" {
  value = module.network.subnet_private_gitlab_id
}

output "subnet_private_id" {
  value = module.network.subnet_private_id
}

output "sg_bastion_id" {
  value = module.network.sg_bastion_id
}

output "sg_redis_id" {
  value = module.network.sg_redis_id
}

output "sg_postgres_id" {
  value = module.network.sg_postgres_id
}

output "sg_gitlab_id" {
  value = module.network.sg_gitlab_id
}

output "sg_alb_gitlab_external_id" {
  value = module.network.sg_alb_gitlab_external_id
}

output "sg_alb_gitlab_internal_id" {
  value = module.network.sg_alb_gitlab_internal_id
}

output "sg_runner_id" {
  value = module.network.sg_runner_id
}

output "aws_eip_bastion_id" {
  value = module.network.aws_eip_bastion_id
}

output "efs_file_system_gitlab_dns_name" {
  value = module.network.efs_file_system_gitlab_dns_name
}

output "iam_instance_profile_name" {
  value = module.network.iam_instance_profile_name
}

output "ssh_key" {
  value = module.network.ssh_key
}
