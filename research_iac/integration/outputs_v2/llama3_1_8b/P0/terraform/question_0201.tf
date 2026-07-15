provider "aws" {
  region = "us-east1"
}

resource "aws_iam_role" "msk_cluster" {
  name        = "MSKClusterRole"
  description = "For Amazon MSK cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "msk.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "msk_cluster_policy" {
  name        = "MSKClusterPolicy"
  description = "For Amazon MSK cluster"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:EnableAlarmActions",
          "cloudwatch:DisableAlarmActions",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "msk_cluster_attach" {
  role       = aws_iam_role.msk_cluster.name
  policy_arn = aws_iam_policy.msk_cluster_policy.arn
}

resource "aws_msk_cluster" "example" {
  cluster_name           = "my-msk-cluster"
  kafka_version          = "2.3.0"
  number_of_broker_nodes = 3
  broker_node_properties = jsonencode({
    instance_type = "kafka.m5.large"
  })
}