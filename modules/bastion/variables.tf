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

variable "network_remote_state_bucket" {
  type        = string
  description = "bucket"
}

variable "network_remote_state_key" {
  type        = string
  description = "network key"
}

variable "instance_type" {
  type        = string
  description = "instance type"
}
