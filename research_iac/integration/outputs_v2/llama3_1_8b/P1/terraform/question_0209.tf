provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "msk_key" {
  description             = "MSK Key for ${var.cluster_name}"
  deletion_window_in_days = 10
  is_enabled               = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow use of the key"
        Effect    = "Allow"
        Principal = {
          Service = "kafka.${var.aws_region}.amazonaws.com"
        }
        Action   = ["kms:Decrypt", "kms:Encrypt"]
        Resource = "*"
      },
      {
        Sid       = "Allow key admin"
        Effect    = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        }
        Action   = ["kms:*"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_msk_cluster" "msk_cluster" {
  cluster_name           = var.cluster_name
  kafka_version          = "2.6.1"
  number_of_broker_nodes = 3

  broker_node_properties = jsonencode({
    instance_type = "kafka.m5.large"
    ebs_volume_size = 32
    ebs_volume_iops = 3000
  })

  configuration {
    arn      = aws_msk_configuration.cluster_config.arn
    revision = aws_msk_configuration.cluster_config.latest_revision
  }

  encryption_info {
    key_arn   = aws_kms_key.msk_key.arn
    encryption_at_rest_kms_key_provider_type = "KMS"
  }
}

resource "aws_msk_configuration" "cluster_config" {
  cluster_config = jsonencode({
    properties = {
      default.replication.factor = "3"
      broker.id.prefix = "${var.cluster_name}-broker-"
    }
  })
}