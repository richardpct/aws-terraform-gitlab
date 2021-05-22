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

variable "webserver_remote_state_bucket" {
  description = "bucket"
}

variable "webserver_remote_state_key" {
  description = "webserver key"
}

variable "image_id" {
  description = "image id"
}

variable "instance_type" {
  description = "instance type"
}

variable "gitlab_token" {
  description = "gitlab token"
}
