# Configure the provider
provider "aws" {
  region = var.region
}

# Create a new VPC
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "production"
  }
}

# Create two public subnets in the VPC
resource "aws_subnet" "public_us_east_1a" {
  cidr_block     = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id          = aws_vpc.example.id

  tags = {
    Environment = "production"
  }
}

resource "aws_subnet" "public_us_east_1b" {
  cidr_block     = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  vpc_id          = aws_vpc.example.id

  tags = {
    Environment = "production"
  }
}

# Create a new security group for the RDS Aurora MySQL cluster
resource "aws_security_group" "rds_aurora_mysql" {
  name        = "rds-aurora-mysql"
  description = "Security group for RDS Aurora MySQL"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Environment = "production"
  }
}

# Create a new IAM role for the RDS Aurora MySQL cluster
resource "aws_iam_role" "rds_aurora_mysql" {
  name = "rds-aurora-mysql"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action: "sts:AssumeRole",
        Principal: {
          Service: "rds.amazonaws.com"
        },
        Effect: "Allow",
        Sid: ""
      }
    ]
  })

  tags = {
    Environment = "production"
  }
}

# Create a new IAM policy for the RDS Aurora MySQL cluster
resource "aws_iam_policy" "rds_aurora_mysql" {
  name   = "rds-aurora-mysql"
  path   = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action: [
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterParameters",
          "rds:DescribeDBClusterSnapshotAttributes",
          "rds:DescribeDBClusterSnapshots",
          "rds:DescribeDBClusters",
          "rds:DescribeDBEngineVersions",
          "rds:DescribeDBInstances",
          "rds:Describe orderable DB instance options"
        ],
        Effect: "Allow",
        Resource: "*"
      }
    ]
  })

  tags = {
    Environment = "production"
  }
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "rds_aurora_mysql" {
  role       = aws_iam_role.rds_aurora_mysql.name
  policy_arn = aws_iam_policy.rds_aurora_mysql.arn
}

# Create a new secret in AWS Secrets Manager for the RDS Aurora MySQL cluster
resource "aws_secretsmanager_secret" "rds_aurora_mysql" {
  name = "rds-aurora-mysql"

  tags = {
    Environment = "production"
  }
}

# Store the database credentials in the secret
resource "aws_secretsmanager_secret_version" "rds_aurora_mysql" {
  secret_id = aws_secretsmanager_secret.rds_aurora_mysql.id

  secret_string = jsonencode({
    username = "admin",
    password = "MySuperSecretPassword123!"
  })
}

# Create a new RDS Aurora MySQL cluster
resource "aws_rds_cluster" "example" {
  engine            = "aurora-mysql"
  engine_mode       = "global"
  instance_class    = "db.r5.large"
  availability_zones = ["us-east-1a", "us-east-1b"]
  storage_encrypted  = true

  db_subnet_group_name = aws_db_subnet_group.example.name
  security_groups       = [aws_security_group.rds_aurora_mysql.id]
  parameter_group_name  = aws_rds_parameter_group.example.name
  master_username      = "admin"
  master_user_password = aws_secretsmanager_secret_version.rds_aurora_mysql.secret_string

  tags = {
    Environment = "production"
  }
}