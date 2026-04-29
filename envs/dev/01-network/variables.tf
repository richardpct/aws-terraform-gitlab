variable "aws_profile" {
  type        = string
  description = "aws profile"
}

variable "region" {
  type        = string
  description = "region"
}

variable "bucket" {
  type        = string
  description = "bucket"
}

variable "key_network" {
  type        = string
  description = "key network"
}

variable "my_ip_address" {
  type        = string
  description = "cidr block allowed to connect through ssh"
}

variable "ssh_public_key" {
  type        = string
  description = "ssh public key"
}
