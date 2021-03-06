variable "region" {
  description = "region"
}

variable "env" {
  description = "environment"
}

variable "base_remote_state_bucket" {
  description = "bucket"
}

variable "base_remote_state_key" {
  description = "base key"
}

variable "database_remote_state_bucket" {
  description = "bucket"
}

variable "database_remote_state_key" {
  description = "database key"
}

variable "image_id" {
  description = "image id"
}

variable "instance_type" {
  description = "instance type"
}

variable "gitlab_pass" {
  description = "gitlab pass"
}

variable "gitlab_size_desired" {
  description = "gitlab size desired"
}

variable "postgres_user" {
  description = "postgres user"
}

variable "postgres_pass" {
  description = "postgres pass"
}
