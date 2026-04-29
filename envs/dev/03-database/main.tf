module "database" {
  source = "../../../modules/database"
  aws_profile                 = var.aws_profile
  region                      = var.region
  env                         = "dev"
  network_remote_state_bucket = var.bucket
  network_remote_state_key    = var.key_network
  redis_type                  = "cache.t4g.micro"
  postgres_type               = "db.t3.micro"
  postgres_user               = var.postgres_user
  postgres_pass               = var.postgres_pass
}
