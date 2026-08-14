provider "aws" {
  region = "us-east-2"
}

data "aws_secretsmanager_secret" "msk_cluster_password" {
  name = "MSKClusterPassword"
}

resource "aws_kms_key" "msk_encryption_key" {
  description             = "Managed MSK cluster encryption key"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "msk_encryption_key_alias" {
  name          = "alias/MSKClusterEncryptionKey"
  target_key_id = aws_kms_key.msk_encryption_key.key_id
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "msk_cluster_role" {
  name               = "ManagedMSKClusterRole"
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

resource "aws_iam_role_policy" "msk_cluster_policy" {
  name   = "ManagedMSKClusterPolicy"
  role   = aws_iam_role.msk_cluster_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kafka:CreateConfiguration",
          "kafka:DeleteConfiguration",
          "kafka:DescribeCluster",
          "kafka:GetClusterMetric",
          "kafka:GetClusterUptimeSummary",
          "kafka:GetConfiguration",
          "kafka:ListClusters",
          "kms:Decrypt",
        ]
        Effect = "Allow"
        Resource = [
          aws_kafka_cluster.msk_cluster.arn,
          aws_kms_key.msk_encryption_key.arn,
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "msk_cluster_instance_profile" {
  name = "ManagedMSKClusterInstanceProfile"
  role = aws_iam_role.msk_cluster_role.name
}

data "aws_vpc" "current" {}

resource "aws_security_group" "msk_cluster_sg" {
  name        = "ManagedMSKClusterSG"
  description = "Security group for managed MSK cluster"
  vpc_id      = data.aws_vpc.current.id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
}

resource "aws_kafka_cluster" "msk_cluster" {
  name       = "ManagedMSKCluster"
  kafka_version = "KAFKA_2_6_0_3_4_0"
  number_of_broker_nodes   = 3
  subnet_ids                  = [data.aws_subnet.current.id]
  enhanced_monitoring_enabled = true

  encryption_in_transit {
    use_server_side_encryption = true
  }

  depends_on = [
    aws_security_group.msk_cluster_sg,
  ]
}