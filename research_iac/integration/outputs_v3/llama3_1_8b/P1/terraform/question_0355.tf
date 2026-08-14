# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create a VPC with two subnets
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.${count.index}.0/24"
  availability_zone = "${var.region}a"
}

# Create a security group for the RDS cluster
resource "aws_security_group" "example" {
  name        = "rds-sg"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
}

# Create an IAM role for the RDS cluster
resource "aws_iam_role" "example" {
  name        = "rds-iam-role"
  description = "RDS IAM Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "example" {
  name        = "rds-iam-policy"
  description = "RDS IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeClusters",
          "rds:DescribeInstances",
          "rds:ModifyCluster",
          "rds:ModifyInstance",
        ]
        Effect = "Allow"
        Resource = aws_rds_cluster.example.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

# Create a Secrets Manager secret for the RDS cluster
resource "aws_secretsmanager_secret" "example" {
  name        = "rds-secret"
  description = "RDS Secret"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    username = "username",
    password = "password",
  })
}

# Create an RDS Aurora MySQL cluster with a proxy for enhanced connection management
resource "aws_rds_cluster" "example" {
  cluster_identifier      = "rds-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.12"
  instance_class          = "db.r4.large"
  database_name           = "database"
  master_username         = aws_secretsmanager_secret.example.name
  master_password         = aws_secretsmanager_secret_version.example.secret_string
  vpc_security_group_ids  = [aws_security_group.example.id]
  cluster_parameter_group_name = "default.aurora-mysql5.7"
  backup_retention_period = "5 days"
  preferred_backup_window = "07:00-09:00"

  iam_database_authentication_enabled = true

  tags = {
    Name        = "rds-cluster"
    Environment = "dev"
  }
}

resource "aws_rds_cluster_instance" "example" {
  cluster_identifier      = aws_rds_cluster.example.id
  instance_class          = "db.r4.large"
  engine                  = aws_rds_cluster.example.engine
  engine_version          = aws_rds_cluster.example.engine_version
  database_name           = aws_rds_cluster.example.database_name
  master_username         = aws_secretsmanager_secret.example.name
  master_password         = aws_secretsmanager_secret_version.example.secret_string
}

# Create an IAM role for the RDS proxy
resource "aws_iam_role" "rds-proxy-iam-role" {
  name        = "rds-proxy-iam-role"
  description = "RDS Proxy IAM Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "rds-proxy-iam-policy" {
  name        = "rds-proxy-iam-policy"
  description = "RDS Proxy IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeClusters",
          "rds:DescribeInstances",
          "rds:ModifyCluster",
          "rds:ModifyInstance",
        ]
        Effect = "Allow"
        Resource = aws_rds_cluster.example.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds-proxy-iam-policy-attachment" {
  role       = aws_iam_role.rds-proxy-iam-role.name
  policy_arn = aws_iam_policy.rds-proxy-iam-policy.arn
}