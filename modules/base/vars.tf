locals {
  ssh_port      = 22
  http_port     = 80
  https_port    = 443
  redis_port    = 6379
  postgres_port = 5432
  gitlab_port   = 80
  nfs_port      = 2049
  anywhere      = ["0.0.0.0/0"]
}

variable "region" {
  description = "region"
}

variable "env" {
  description = "environment"
}

variable "vpc_cidr_block" {
  description = "vpc cidr block"
}

variable "subnet_public_a" {
  description = "public subnet A"
}

variable "subnet_public_b" {
  description = "public subnet B"
}

variable "subnet_private_gitlab_a" {
  description = "private gitlab subnet A"
}

variable "subnet_private_gitlab_b" {
  description = "private gitlab subnet B"
}

variable "subnet_private_db_a" {
  description = "private db subnet A"
}

variable "subnet_private_db_b" {
  description = "private db subnet B"
}

variable "cidr_allowed_ssh" {
  description = "cidr block allowed to connect through SSH"
}

variable "ssh_public_key" {
  description = "ssh public key"
}
