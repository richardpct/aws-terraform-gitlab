module "runner" {
  source                      = "../../../modules/runner"
  aws_profile                 = var.aws_profile
  region                      = var.region
  env                         = "dev"
  network_remote_state_bucket = var.bucket
  network_remote_state_key    = var.key_network
  gitlab_remote_state_bucket  = var.bucket
  gitlab_remote_state_key     = var.key_gitlab
  instance_type               = "t2.micro"
  runner_nb_desired           = var.runner_nb_desired
  gitlab_token                = var.gitlab_token
}
