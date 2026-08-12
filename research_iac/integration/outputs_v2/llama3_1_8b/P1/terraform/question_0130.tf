provider "aws" {
  region = var.region
}

data "aws_region" "current" {}

# Create a new VPC with private subnets
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "example-vpc" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.${count.index}.0/24"
  availability_zone = data.aws_region.current.name
  tags              = { Name = "example-private-subnet-${count.index}" }
}

# Create an EFS file system for shared storage
resource "aws_efs_file_system" "shared_storage" {
  creation_token   = "example-efs"
  performance_mode = "generalPurpose"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = { Name = "example-shared-storage" }
}

# Create an EFS mount target in the private subnet
resource "aws_efs_mount_target" "private" {
  file_system_id = aws_efs_file_system.shared_storage.id
  vpc_id         = aws_vpc.example.id
  subnet_id      = aws_subnet.private[0].id

  security_groups = [aws_security_group.efs.id]
}

# Create an IAM role for the EC2 instances to access EFS
resource "aws_iam_role" "ec2_instance_role" {
  name        = "example-ec2-instance-role"
  description = "Role for EC2 instances to access EFS"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM policy for the EC2 instances to access EFS
resource "aws_iam_policy" "efs_access_policy" {
  name        = "example-efs-access-policy"
  description = "Policy for EC2 instances to access EFS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["elasticfilesystem:ClientMount"]
        Effect = "Allow"
        Resource = aws_efs_file_system.shared_storage.arn
      }
    ]
  })
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "ecs_exec_role_attach" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.efs_access_policy.arn
}

# Create an EC2 instance in the private subnet mounting EFS
resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Security group for example resources"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  count         = 2
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.example.id]
  subnet_id       = aws_subnet.private[count.index].id

  iam_instance_profile = aws_iam_role.ec2_instance_role.name

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y amazon-efs-utils",
      "sudo mount -t efs ${aws_efs_file_system.shared_storage.dns_name}:/ /mnt",
    ]
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}