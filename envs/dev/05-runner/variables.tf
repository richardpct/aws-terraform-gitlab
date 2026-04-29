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

variable "key_gitlab" {
  type        = string
  description = "key gitlab"
}

variable "key_runner" {
  type        = string
  description = "key runner"
}

variable "runner_nb_desired" {
  type        = number
  description = "number of runner desired"
  default     = 1
}

variable "gitlab_token" {
  type        = string
  description = "gitlab token"
}
