resource "aws_efs_file_system" "example" {
  creation_token = "example"

  encrypted = true

  tags = {
    Name = "example"
  }
}

resource "aws_efs_mount_target" "example" {
  file_system_id = aws_efs_file_system.example.id
  subnet_id      = "subnet-12345678"
  security_groups = [
    "sg-12345678",
  ]
}

resource "aws_efs_access_point" "example" {
  file_system_id = aws_efs_file_system.example.id

  root_directory {
    path = "/example"
  }

  posix_policy {
    gid = "1001"
    uid = "1001"
  }
}