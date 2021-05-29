output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "subnet_public_a_id" {
  value = aws_subnet.public_a.id
}

output "subnet_public_b_id" {
  value = aws_subnet.public_b.id
}

output "subnet_private_gitlab_a_id" {
  value = aws_subnet.private_gitlab_a.id
}

output "subnet_private_gitlab_b_id" {
  value = aws_subnet.private_gitlab_b.id
}

output "subnet_private_a_id" {
  value = aws_subnet.private_a.id
}

output "subnet_private_b_id" {
  value = aws_subnet.private_b.id
}

output "sg_bastion_id" {
  value = aws_security_group.bastion.id
}

output "sg_redis_id" {
  value = aws_security_group.redis.id
}

output "sg_postgres_id" {
  value = aws_security_group.postgres.id
}

output "sg_gitlab_id" {
  value = aws_security_group.gitlab.id
}

output "sg_alb_gitlab_public_id" {
  value = aws_security_group.alb_gitlab_public.id
}

output "sg_alb_gitlab_internal_id" {
  value = aws_security_group.alb_gitlab_internal.id
}

output "sg_runner_id" {
  value = aws_security_group.runner.id
}

output "aws_eip_bastion_id" {
  value = aws_eip.bastion.id
}

output "efs_file_system_gitlab_dns_name" {
  value = aws_efs_file_system.gitlab.dns_name
}

output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.profile.name
}

output "ssh_key" {
  value = aws_key_pair.deployer.key_name
}
