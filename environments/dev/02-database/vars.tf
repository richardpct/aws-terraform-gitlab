variable "bucket" {
  description = "bucket where terraform states are stored"
}

variable "dev_base_key" {
  description = "terraform state for dev environment"
}

variable "dev_postgres_user" {
  description = "postgres user"
}

variable "dev_postgres_pass" {
  description = "postgres pass"
}
