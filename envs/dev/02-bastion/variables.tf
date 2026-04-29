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
  description = "bucket where OpenTofu states are stored"
}

variable "key_network" {
  type        = string
  description = "key network"
}

variable "key_bastion" {
  type        = string
  description = "key bastion"
}
