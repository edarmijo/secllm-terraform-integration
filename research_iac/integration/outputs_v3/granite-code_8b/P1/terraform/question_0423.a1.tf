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
    aws_security_group.example.id,
  ]
}

resource "aws_efs_access_point" "example" {
  file_system_id = aws_efs_file_system.example.id

  root_directory {
    path = "/"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "755"
    }
  }

  pos_ix_user {
    uid = "1001"
    gid = "1001"
  }
}

resource "aws_security_group" "example" {
  name_prefix = "example"
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "example"
  }
}