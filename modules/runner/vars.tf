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

variable "gitlab_remote_state_bucket" {
  description = "bucket"
}

variable "gitlab_remote_state_key" {
  description = "gitlab key"
}

variable "image_id" {
  description = "image id"
}

variable "instance_type" {
  description = "instance type"
}

variable "runner_nb_desired" {
  description = "number of runner desired"
}

variable "gitlab_token" {
  description = "gitlab token"
}
