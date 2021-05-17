terraform {
  backend "s3" {}
}

module "webserver" {
  source = "../../../modules/webserver"

  region                       = "eu-west-3"
  env                          = "dev"
  base_remote_state_bucket     = var.bucket
  base_remote_state_key        = var.dev_base_key
  database_remote_state_bucket = var.bucket
  database_remote_state_key    = var.dev_database_key
  instance_type                = "t2.medium"
  image_id                     = "ami-072ec828dae86abe5"  # CentOS 7
  postgres_user                = var.dev_postgres_user
  postgres_pass                = var.dev_postgres_pass
}
