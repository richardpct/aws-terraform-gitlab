module "gitlab" {
  source                       = "../../../modules/gitlab"
  aws_profile                  = var.aws_profile
  region                       = var.region
  env                          = "dev"
  network_remote_state_bucket  = var.bucket
  network_remote_state_key     = var.key_network
  database_remote_state_bucket = var.bucket
  database_remote_state_key    = var.key_database
  instance_type                = "c5.xlarge"
  gitlab_pass                  = var.gitlab_pass
  gitlab_size_desired          = var.gitlab_size_desired
  postgres_user                = var.postgres_user
  postgres_pass                = var.postgres_pass
}
