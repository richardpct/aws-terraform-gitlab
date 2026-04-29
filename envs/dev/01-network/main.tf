module "network" {
  source                  = "../../../modules/network"
  aws_profile             = var.aws_profile
  region                  = var.region
  env                     = "dev"
  vpc_cidr_block          = "10.0.0.0/16"
  subnet_public           = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  subnet_private_gitlab   = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  subnet_private          = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
  cidr_allowed_ssh        = var.my_ip_address
  ssh_public_key          = var.ssh_public_key
}
