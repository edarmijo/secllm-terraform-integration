provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "aurora_mysql_cluster_password" {
  name        = "${var.cluster_name}-password"
  description = "Password for the Aurora MySQL cluster"
}

resource "aws_secretsmanager_secret_version" "aurora_mysql_cluster_password" {
  secret_id     = aws_secretsmanager_secret.aurora_mysql_cluster_password.id
  secret_string = jsonencode({"username": var.cluster_username, "password": random_password.password.result})
}

data "aws_iam_policy_document" "cluster_role_policy" {
  statement {
    sid       = "AllowClusterManagement"
    actions   = ["rds:DescribeClusters", "rds:CreateDBInstance", "rds:ModifyDBInstance"]
    resources = [aws_rds_cluster.cluster.arn]
  }
}

data "aws_iam_policy_document" "instance_role_policy" {
  statement {
    sid       = "AllowDatabaseAccess"
    actions   = ["rds:DescribeDBInstances", "rds:CreateDBInstance", "rds:ModifyDBInstance"]
    resources = [aws_rds_cluster.cluster.arn]
  }
}

resource "aws_iam_role" "cluster_role" {
  name        = "${var.cluster_name}-role"
  description = "Role for managing the Aurora MySQL cluster"

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

resource "aws_iam_role_policy_attachment" "cluster_role_attach" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = data.aws_iam_policy_document.cluster_role_policy.arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  name        = "${var.cluster_name}-profile"
  description = "Instance profile for the Aurora MySQL cluster"

  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name        = "${var.cluster_name}-instance-role"
  description = "Role for instances in the Aurora MySQL cluster"

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

resource "aws_iam_role_policy_attachment" "instance_role_attach" {
  role       = aws_iam_role.instance_role.name
  policy_arn = data.aws_iam_policy_document.instance_role_policy.arn
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier      = var.cluster_name
  engine                  = "aurora-mysql"
  master_username         = var.cluster_username
  master_user_password    = aws_secretsmanager_secret_version.aurora_mysql_cluster_password.secret_string
  database_name           = "mydb"
  vpc_security_group_ids  = [aws_security_group.cluster_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.cluster_subnet_group.name

  iam_database_authentication_enabled = true

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "cluster_instance" {
  cluster_identifier      = aws_rds_cluster.cluster.id
  instance_class          = "db.r5.large"
  engine                  = aws_rds_cluster.cluster.engine
  database_name           = aws_rds_cluster.cluster.database_name
  db_subnet_group_name   = aws_db_subnet_group.cluster_subnet_group.name

  vpc_security_group_ids  = [aws_security_group.cluster_sg.id]
}

resource "aws_security_group" "cluster_sg" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for the Aurora MySQL cluster"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "cluster_subnet_group" {
  name       = "${var.cluster_name}-subnet-group"
  description = "Subnet group for the Aurora MySQL cluster"

  subnet_ids = var.subnet_ids
}