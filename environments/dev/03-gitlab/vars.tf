variable "bucket" {
  description = "bucket where terraform states are stored"
}

variable "dev_base_key" {
  description = "terraform state for dev environment"
}

variable "dev_database_key" {
  description = "terraform state for dev environment"
}

variable "dev_gitlab_pass" {
  description = "gitlab pass"
}

variable "dev_postgres_user" {
  description = "postgres user"
}

variable "dev_postgres_pass" {
  description = "postgres pass"
}
