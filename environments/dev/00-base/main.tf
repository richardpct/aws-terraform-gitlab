terraform {
  backend "s3" {}
}

module "base" {
  source = "../../../modules/base"

  region                  = "eu-west-3"
  env                     = "dev"
  vpc_cidr_block          = "10.0.0.0/16"
  subnet_public_a         = "10.0.0.0/24"
  subnet_public_b         = "10.0.1.0/24"
  subnet_private_gitlab_a = "10.0.2.0/24"
  subnet_private_gitlab_b = "10.0.3.0/24"
  subnet_private_a        = "10.0.4.0/24"
  subnet_private_b        = "10.0.5.0/24"
  cidr_allowed_ssh        = var.my_ip_address
  ssh_public_key          = var.ssh_public_key
}
