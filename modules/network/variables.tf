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

variable "aws_profile" {
  type        = string
  description = "aws profile"
}

variable "region" {
  type        = string
  description = "region"
}

variable "env" {
  type        = string
  description = "environment"
}

variable "vpc_cidr_block" {
  type        = string
  description = "vpc cidr block"
}

variable "subnet_public" {
  type        = list(string)
  description = "public subnet"
}

variable "subnet_private" {
  type        = list(string)
  description = "private subnet"
}

variable "subnet_private_gitlab" {
  type        = list(string)
  description = "private gitlab subnet"
}

variable "cidr_allowed_ssh" {
  type        = string
  description = "cidr block allowed to connect through ssh"
}

variable "ssh_public_key" {
  type        = string
  description = "ssh public key"
}
