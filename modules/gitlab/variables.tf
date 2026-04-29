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

variable "database_remote_state_bucket" {
  type        = string
  description = "bucket"
}

variable "database_remote_state_key" {
  type        = string
  description = "database key"
}

variable "instance_type" {
  type        = string
  description = "instance type"
}

variable "gitlab_pass" {
  type        = string
  description = "gitlab pass"
}

variable "gitlab_size_desired" {
  type        = string
  description = "gitlab size desired"
}

variable "postgres_user" {
  type        = string
  description = "postgres user"
}

variable "postgres_pass" {
  type        = string
  description = "postgres pass"
}
