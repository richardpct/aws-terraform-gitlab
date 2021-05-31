variable "bucket" {
  description = "bucket where terraform states are stored"
}

variable "dev_base_key" {
  description = "terraform state for dev environment"
}

variable "dev_gitlab_key" {
  description = "terraform state for dev environment"
}

variable "runner_nb_desired" {
  description = "number of runner desired"
  type        = number
  default     = 1
}

variable "gitlab_token" {
  description = "gitlab token"
}
