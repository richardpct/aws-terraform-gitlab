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
  image_id                     = "ami-00983e8a26e4c9bd9"  # Ubuntu LTS
  gitlab_pass                  = var.dev_gitlab_pass
  gitlab_size_desired          = var.gitlab_size_desired
  postgres_user                = var.dev_postgres_user
  postgres_pass                = var.dev_postgres_pass
}
