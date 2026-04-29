terraform {
  backend "s3" {
    profile = var.aws_profile
    bucket  = var.bucket
    key     = var.key_network
    region  = var.region
  }
}
