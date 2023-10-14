terraform {
  backend "s3" {}
}

module "bastion" {
  source = "../../../modules/bastion"

  region                   = "eu-west-3"
  env                      = "dev"
  base_remote_state_bucket = var.bucket
  base_remote_state_key    = var.dev_base_key
  instance_type            = "t2.micro"
  image_id                 = "ami-0271422acce1aee9b"  # Amazon Linux 2023
}
