resource "aws_key_pair" "deployer" {
  key_name   = "deployer-ssh-key-${var.env}"
  public_key = var.ssh_public_key
}
