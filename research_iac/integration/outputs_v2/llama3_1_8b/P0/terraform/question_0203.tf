provider "aws" {
  region = "us-east1"
}

resource "aws_cloudwatch_log_group" "msk_logs" {
  name              = "/aws/msk/clusters/${var.cluster_name}"
  retention_in_days = 30
}

resource "aws_msk_cluster" "example" {
  cluster_name           = var.cluster_name
  kafka_version          = "2.6.1"
  number_of_node_groups = 1

  vpc_settings {
    subnet_ids         = [var.subnet_id]
    security_group_ids = [var.security_group_id]
  }

  logging_info {
    enabled              = true
    cloudwatch_logging_info {
      log_group        = aws_cloudwatch_log_group.msk_logs.name
      role_arn         = aws_iam_role.msk_cluster.arn
    }
  }
}

resource "aws_iam_role" "msk_cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kafka.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "msk_cluster" {
  name        = "${var.cluster_name}-cluster-policy"
  description = "Policy for MSK cluster"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "msk_cluster" {
  role       = aws_iam_role.msk_cluster.name
  policy_arn = aws_iam_policy.msk_cluster.arn
}