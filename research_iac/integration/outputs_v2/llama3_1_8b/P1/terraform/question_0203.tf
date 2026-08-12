provider "aws" {
  region = "us-east-1"
}

resource "aws_kms_key" "msk_key" {
  description             = "Managed MSK key for encryption"
  deletion_window_in_days = 10
  is_enabled               = true
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "managed-msk-cluster-logs"
  retention_in_days = 30
}

data "aws_secretsmanager_secret" "msk_cluster_credentials" {
  name = "MSKClusterCredentials"
}

data "aws_secretsmanager_secret_version" "msk_cluster_credentials" {
  secret_id = data.aws_secretsmanager_secret.msk_cluster_credentials.id
}

resource "aws_msk_cluster" "managed_msk_cluster" {
  cluster_name           = "managed-msk-cluster"
  kafka_version          = "2.6.1"
  number_of_node_groups = 1

  node_group {
    instance_type = "kafka.m5.large"
    auto_scaling_properties {
      instance_count = 3
    }
  }

  encryption_info {
    key_arn = aws_kms_key.msk_key.arn
  }

  logging_info {
    cloudwatch_logging_info {
      enabled              = true
      log_group         = aws_cloudwatch_log_group.log_group.name
      role_arn           = aws_iam_role.msk_cluster_logging.arn
    }
  }
}

resource "aws_iam_role" "msk_cluster_logging" {
  name        = "MSKClusterLoggingRole"
  description = "IAM role for MSK cluster logging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kafka.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "msk_cluster_logging_policy" {
  name        = "MSKClusterLoggingPolicy"
  description = "IAM policy for MSK cluster logging"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutRecord"
        ]
        Effect = "Allow"
        Resource = aws_cloudwatch_log_group.log_group.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "msk_cluster_logging_attach" {
  role       = aws_iam_role.msk_cluster_logging.name
  policy_arn = aws_iam_policy.msk_cluster_logging_policy.arn
}