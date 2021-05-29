resource "aws_efs_file_system" "gitlab" {
  tags = {
    Name = "gitlab-efs"
  }
}

resource "aws_efs_mount_target" "mount_target_a" {
  file_system_id  = aws_efs_file_system.gitlab.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "mount_target_b" {
  file_system_id  = aws_efs_file_system.gitlab.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs.id]
}
