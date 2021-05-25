terraform {
  backend "s3" {}
}

module "gitlab" {
  source = "../../../modules/gitlab"

  region                       = "eu-west-3"
  env                          = "dev"
  base_remote_state_bucket     = var.bucket
  base_remote_state_key        = var.dev_base_key
  database_remote_state_bucket = var.bucket
  database_remote_state_key    = var.dev_database_key
  instance_type                = "c5.xlarge"
  image_id                     = "ami-072ec828dae86abe5"  # CentOS 7
  gitlab_pass                  = var.dev_gitlab_pass
  postgres_user                = var.dev_postgres_user
  postgres_pass                = var.dev_postgres_pass
}
