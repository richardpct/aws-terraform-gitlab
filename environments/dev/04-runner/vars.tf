variable "bucket" {
  description = "bucket where terraform states are stored"
}

variable "dev_base_key" {
  description = "terraform state for dev environment"
}

variable "dev_gitlab_key" {
  description = "terraform state for dev environment"
}

variable "gitlab_token" {
  description = "gitlab token"
}
