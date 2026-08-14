provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_msk_cluster" "example" {
  cluster_name           = "msk-cluster"
  kafka_version          = "2.6.1"
  number_of_broker_nodes = 3

  configuration {
    broker_ebs_volume_size = 32
    broker_node_group_info {
      instance_type = "kafka.m5.large"
      ebs_block_device {
        volume_size = 32
      }
    }
  }

  encryption_at_rest {
    kms_key_arn = aws_kms_key.example.arn
  }

  logging_info {
    enabled              = true
    cloudwatch_logging_info {
      enabled         = true
      log_group       = aws_cloudwatch_log_group.example.name
      role_arn        = aws_iam_role.msk.arn
    }
  }
}

resource "aws_msk_configuration" "example" {
  name             = "msk-configuration"
  kafka_versions  = ["2.6.1"]
  server_properties = jsonencode({
    "log.retention.bytes" = "1073741824",
    "log.retention.ms"   = "3600000",
    "log.dirs"           = "/var/lib/kafka/data"
  })
}

resource "aws_kms_key" "example" {
  description             = "MSK Key"
  deletion_window_in_days = 10
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "msk-cluster-log-group"
  retention_in_days = 30
}

resource "aws_s3_bucket" "example" {
  bucket        = "msk-logs-${data.aws_caller_identity.current.account_id}"
  acl           = "private"
  force_destroy = true
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "msk-firehose-delivery-stream"

  destination = "s3"

  s3_configuration {
    role_arn            = aws_iam_role.firehose-execution-role.arn
    compression_format  = "GZIP"
    bucket_arn          = aws_s3_bucket.example.arn
  }
}

resource "aws_security_group" "msk" {
  name        = "msk-security-group"
  description = "Security group for MSK cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }
}

resource "aws_iam_role" "msk" {
  name               = "msk-execution-role"
  description        = "Execution role for MSK cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kafka.${data.aws_region.current.name}.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "msk" {
  name   = "msk-execution-policy"
  role   = aws_iam_role.msk.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = aws_s3_bucket.example.arn
      },
    ]
  })
}

resource "aws_iam_role" "firehose-execution-role" {
  name               = "firehose-execution-role"
  description        = "Execution role for Kinesis Firehose delivery stream"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.${data.aws_region.current.name}.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose-execution-policy" {
  name   = "firehose-execution-policy"
  role   = aws_iam_role.firehose-execution-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = aws_s3_bucket.example.arn
      }
    ]
  })
}