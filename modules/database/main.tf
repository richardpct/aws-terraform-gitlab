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
  subnet_ids = [data.terraform_remote_state.base.outputs.subnet_private_db_a_id, data.terraform_remote_state.base.outputs.subnet_private_db_b_id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "cluster-redis"
  engine               = "redis"
  node_type            = var.instance_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
#  engine_version       = "6.x"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [data.terraform_remote_state.base.outputs.sg_redis_id]
}

resource "aws_db_subnet_group" "postgres" {
  name       = "subnet-postgres-${var.env}"
  subnet_ids = [data.terraform_remote_state.base.outputs.subnet_private_db_a_id, data.terraform_remote_state.base.outputs.subnet_private_db_b_id]
}

resource "aws_db_instance" "postgres" {
  allocated_storage       = 5
  engine                  = "postgres"
#  engine_version       = "5.7"
  instance_class          = "db.t2.micro"
  name                    = "gitlabhq_production"
  username                = "foo"
  password                = "foobarbaz"
#  parameter_group_name    = "default.mysql5.7"
  skip_final_snapshot     = true
  backup_retention_period = 0
  vpc_security_group_ids  = [data.terraform_remote_state.base.outputs.sg_postgres_id]
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
}
