variable "bucket" {
  description = "bucket where terraform states are stored"
}

variable "dev_base_key" {
  description = "terraform state for dev environment"
}

variable "dev_webserver_key" {
  description = "terraform state for dev environment"
}

variable "gitlab_token" {
  description = "gitlab token"
}
