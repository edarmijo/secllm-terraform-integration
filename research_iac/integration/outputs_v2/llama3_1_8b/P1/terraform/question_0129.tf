# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create VPC with CIDR block of /16
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "example-vpc" }
}

# Create public subnet in the VPC
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_availability_zone
  map_public_ip_on_launch = true

  tags = { Name = "example-public-subnet" }
}

# Create private subnets in the VPC
resource "aws_subnet" "private-1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.aws_availability_zone

  tags = { Name = "example-private-subnet-1" }
}

resource "aws_subnet" "private-2" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.aws_availability_zone

  tags = { Name = "example-private-subnet-2" }
}

# Create security group for EC2 instances
resource "aws_security_group" "ec2-sg" {
  vpc_id       = aws_vpc.example.id
  name         = "example-ec2-sg"
  description  = "Security group for EC2 instances"

  # Allow inbound traffic on port 22 (SSH)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic on port 80 (HTTP) and port 443 (HTTPS)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# Create IAM role for EC2 instances
resource "aws_iam_role" "ec2-role" {
  name        = "example-ec2-role"
  description = "IAM role for EC2 instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Create IAM policy for EC2 instances
resource "aws_iam_policy" "ec2-policy" {
  name        = "example-ec2-policy"
  description = "IAM policy for EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.example.arn
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach IAM policy to EC2 role
resource "aws_iam_role_policy_attachment" "ec2-attachment" {
  role       = aws_iam_role.ec2-role.name
  policy_arn = aws_iam_policy.ec2-policy.arn
}

# Create EC2 instance in public subnet running web servers
resource "aws_instance" "web-server" {
  ami           = var.aws_amis[var.aws_region]
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  subnet_id       = aws_subnet.public.id

  iam_instance_profile = aws_iam_role.ec2-role.name
}

# Create EC2 instance in private subnet running application servers
resource "aws_instance" "app-server" {
  ami           = var.aws_amis[var.aws_region]
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  subnet_id       = aws_subnet.private-1.id

  iam_instance_profile = aws_iam_role.ec2-role.name
}

# Create RDS instance in private subnet serving as database
resource "aws_db_instance" "database" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "example-db"
  username             = var.rds_username
  password             = var.rds_password
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  subnet_id           = aws_subnet.private-2.id

  skip_final_snapshot = true
}

# Create AWS Secrets Manager secret for RDS instance
resource "aws_secretsmanager_secret" "rds-secret" {
  name = "example-rds-secret"
}

resource "aws_secretsmanager_secret_version" "rds-secret-version" {
  secret_id     = aws_secretsmanager_secret.rds-secret.id
  secret_string = jsonencode({
    username = var.rds_username,
    password = var.rds_password,
  })
}