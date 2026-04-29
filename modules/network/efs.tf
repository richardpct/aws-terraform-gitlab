resource "aws_efs_file_system" "gitlab" {
  tags = {
    Name = "gitlab-efs-${var.env}"
  }
}

resource "aws_efs_mount_target" "gitlab" {
  count           = length(var.subnet_private)
  file_system_id  = aws_efs_file_system.gitlab.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
