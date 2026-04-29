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

variable "redis_type" {
  type        = string
  description = "redis type"
}

variable "postgres_type" {
  type        = string
  description = "postgres type"
}

variable "postgres_user" {
  type        = string
  description = "postgres user"
}

variable "postgres_pass" {
  type        = string
  description = "postgres pass"
}
