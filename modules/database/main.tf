data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    profile = var.aws_profile
    bucket  = var.network_remote_state_bucket
    key     = var.network_remote_state_key
    region  = var.region
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "subnet-redis-${var.env}"
  subnet_ids = data.terraform_remote_state.network.outputs.subnet_private_id[*]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "cluster-redis"
  engine               = "redis"
  node_type            = var.redis_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.x"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [data.terraform_remote_state.network.outputs.sg_redis_id]
}

resource "aws_db_subnet_group" "postgres" {
  name       = "subnet-postgres-${var.env}"
  subnet_ids = data.terraform_remote_state.network.outputs.subnet_private_id[*]
}

resource "aws_db_instance" "postgres" {
  allocated_storage       = 5
  engine                  = "postgres"
  instance_class          = var.postgres_type
  db_name                 = "gitlabhq_production"
  username                = var.postgres_user
  password                = var.postgres_pass
  skip_final_snapshot     = true
  backup_retention_period = 0
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
  vpc_security_group_ids  = [data.terraform_remote_state.network.outputs.sg_postgres_id]
}
