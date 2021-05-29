provider "aws" {
  region = var.region
}

data "terraform_remote_state" "base" {
  backend = "s3"

  config = {
    bucket = var.base_remote_state_bucket
    key    = var.base_remote_state_key
    region = var.region
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "subnet-redis-${var.env}"
  subnet_ids = [data.terraform_remote_state.base.outputs.subnet_private_a_id, data.terraform_remote_state.base.outputs.subnet_private_b_id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "cluster-redis"
  engine               = "redis"
  node_type            = var.redis_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [data.terraform_remote_state.base.outputs.sg_redis_id]
}

resource "aws_db_subnet_group" "postgres" {
  name       = "subnet-postgres-${var.env}"
  subnet_ids = [data.terraform_remote_state.base.outputs.subnet_private_a_id, data.terraform_remote_state.base.outputs.subnet_private_b_id]
}

resource "aws_db_instance" "postgres" {
  allocated_storage       = 5
  engine                  = "postgres"
  instance_class          = var.postgres_type
  name                    = "gitlabhq_production"
  username                = var.postgres_user
  password                = var.postgres_pass
  skip_final_snapshot     = true
  backup_retention_period = 0
  vpc_security_group_ids  = [data.terraform_remote_state.base.outputs.sg_postgres_id]
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
}
