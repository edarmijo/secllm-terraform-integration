provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eb_ec2_profile" {
  name               = "eb_ec2_profile"
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

resource "aws_iam_role_policy" "eb_ec2_policy" {
  name   = "eb_ec2_policy"
  role   = aws_iam_role.eb_ec2_profile.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:ModifyInstanceAttribute",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      },
      {
        Action = [
          "rds:CreateDBInstance",
          "rds:CreateDBCluster",
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster"
        ]
        Effect = "Allow"
        Resource = [
          aws_rds_instance.prod_db.arn,
          aws_rds_cluster.staging_db.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eb_ec2_attach" {
  role       = aws_iam_role.eb_ec2_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSServiceRolePolicy"
}

data "aws_secretsmanager_secret" "rds_prod_db_password" {
  name = var.rds_prod_db_password_secret_name
}

data "aws_secretsmanager_secret_version" "rds_prod_db_password" {
  secret_id = data.aws_secretsmanager_secret.rds_prod_db_password.id
}

resource "aws_rds_cluster" "staging_db" {
  cluster_identifier        = "staging-db-cluster"
  database_name             = "staging_db"
  master_username           = var.staging_db_master_username
  master_user_password      = data.aws_secretsmanager_secret_version.rds_prod_db_password.secret_string
  vpc_security_group_ids    = [aws_security_group.prod_sg.id]
  db_subnet_group_name     = aws_db_subnet_group.prod_subnet_group.name
  skip_final_snapshot       = true
}

resource "aws_rds_cluster_instance" "staging_db_instance" {
  cluster_identifier      = aws_rds_cluster.staging_db.id
  instance_class          = var.staging_db_instance_type
  engine                  = var.staging_db_engine
  database_name           = aws_rds_cluster.staging_db.database_name
  master_username         = aws_rds_cluster.staging_db.master_username
  master_user_password    = aws_rds_cluster.staging_db.master_user_password
}

resource "aws_security_group" "prod_sg" {
  name        = "prod-sg"
  description = "Security group for prod environment"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.prod_sg_cidr_block]
  }
}

resource "aws_db_subnet_group" "prod_subnet_group" {
  name       = "prod-subnet-group"
  description = "Subnet group for prod environment"

  subnet_ids = var.subnet_ids
}

resource "aws_rds_instance" "prod_db" {
  instance_class          = var.prod_db_instance_type
  engine                  = var.prod_db_engine
  database_name           = aws_rds_cluster.staging_db.database_name
  master_username         = aws_rds_cluster.staging_db.master_username
  master_user_password    = aws_rds_cluster.staging_db.master_user_password
  vpc_security_group_ids  = [aws_security_group.prod_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.prod_subnet_group.name
}

resource "aws_elastic_beanstalk_environment" "prod_env" {
  name                = "prod-env"
  application         = var.elastic_beanstalk_app_name
  environment_name    = "prod-env"
  tier                = "webserver-medium"
  version_label       = "v1"
  setting {
    namespace        = "aws:ec2:vpc"
    name             = "VPCId"
    value            = var.vpc_id
  }
}

resource "aws_elastic_beanstalk_environment" "staging_env" {
  name                = "staging-env"
  application         = var.elastic_beanstalk_app_name
  environment_name    = "staging-env"
  tier                = "webserver-medium"
  version_label       = "v1"
  setting {
    namespace        = "aws:ec2:vpc"
    name             = "VPCId"
    value            = var.vpc_id
  }
}