terraform {
  backend "s3" {}
}

module "runner" {
  source = "../../../modules/runner"

  region                     = "eu-west-3"
  env                        = "dev"
  base_remote_state_bucket   = var.bucket
  base_remote_state_key      = var.dev_base_key
  gitlab_remote_state_bucket = var.bucket
  gitlab_remote_state_key    = var.dev_gitlab_key
  instance_type              = "t2.micro"
  image_id                   = "ami-00983e8a26e4c9bd9"  # Ubuntu LTS
  runner_nb_desired          = var.runner_nb_desired
  gitlab_token               = var.gitlab_token
}
