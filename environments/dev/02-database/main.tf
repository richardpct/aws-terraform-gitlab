terraform {
  backend "s3" {}
}

module "database" {
  source = "../../../modules/database"

  region                   = "eu-west-3"
  env                      = "dev"
  base_remote_state_bucket = var.bucket
  base_remote_state_key    = var.dev_base_key
  instance_type            = "cache.t2.micro"
}
