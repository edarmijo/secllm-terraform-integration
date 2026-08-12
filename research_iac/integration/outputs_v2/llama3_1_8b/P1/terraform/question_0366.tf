provider "aws" {
  region = var.region
}

data "aws_region" "current" {}

resource "aws_secretsmanager_secret" "database_credentials" {
  name        = "lightsail-managed-database-credentials"
  description = "Credentials for Lightsail managed database"
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id     = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    username = var.database_username
    password = var.database_password
  })
}

data "aws_iam_policy_document" "lightsail_managed_database_role_policy" {
  statement {
    actions = [
      "lightsail:GetInstance",
      "lightsail:CreateDatabase",
      "lightsail:CreateDatabaseParameterGroup",
      "lightsail:ModifyDatabase",
      "lightsail:ModifyDatabaseParameterGroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "lightsail_managed_database_role" {
  name               = "LightsailManagedDatabaseRole"
  description        = "Role for Lightsail managed database"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lightsail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lightsail_managed_database_role_policy" {
  name   = "LightsailManagedDatabaseRolePolicy"
  role   = aws_iam_role.lightsail_managed_database_role.id
  policy = data.aws_iam_policy_document.lightsail_managed_database_role_policy.json
}

data "aws_iam_policy_document" "instance_profile_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.database_credentials.arn]
  }
}

resource "aws_iam_instance_profile" "lightsail_managed_database_instance_profile" {
  name        = "LightsailManagedDatabaseInstanceProfile"
  description = "Instance profile for Lightsail managed database"
  role        = aws_iam_role.lightsail_managed_database_role.id
}

resource "aws_lightsail_database" "example" {
  name                  = var.database_name
  username              = var.database_username
  password              = var.database_password
  master_user_password  = var.database_password
  backup_retention_period = 1
  instance_size          = "db-b-2"
}

resource "aws_lightsail_database_parameter_group" "example" {
  name      = var.database_name
  family    = "mysql5.7"
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }
}