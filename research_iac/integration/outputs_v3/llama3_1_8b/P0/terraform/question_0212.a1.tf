provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "msk_service_role" {
  name        = "msk-service-role-${data.aws_caller_identity.current.account_id}"
  description = "MSK service role for ${data.aws_caller_identity.current.account_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "msk_service_policy" {
  name   = "msk-service-policy-${data.aws_caller_identity.current.account_id}"
  role   = aws_iam_role.msk_service_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:PutObject",
          "s3:GetObject",
          "kinesis:PutRecord",
        ]
        Effect = "Allow"
        Resource = [
          "*",
        ]
      },
    ]
  })
}

resource "aws_iam_role" "msk_cluster_role" {
  name        = "msk-cluster-role-${data.aws_caller_identity.current.account_id}"
  description = "MSK cluster role for ${data.aws_caller_identity.current.account_id}"

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
  name   = "msk-cluster-policy-${data.aws_caller_identity.current.account_id}"
  role   = aws_iam_role.msk_cluster_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:PutObject",
          "s3:GetObject",
          "kinesis:PutRecord",
        ]
        Effect = "Allow"
        Resource = [
          "*",
        ]
      },
    ]
  })
}

resource "aws_msk_cluster" "example" {
  cluster_name                = "msk-cluster-example"
  kafka_version               = "2.6.1"
  number_of_broker_nodes      = 3
  broker_node_group_info {
    instance_type = "kafka.m5.large"
    instance_count = 3
    ebs_volume_size = 32
    security_groups = [aws_security_group.example.id]
  }
  vpc_id                      = aws_vpc.example.id

  encryption_info {
    key_arn = aws_kms_key.example.arn
  }

  open_monitoring {
    prometheus {
      jmx_exporter_enabled = true
    }
  }
}

resource "aws_msk_configuration" "example" {
  name       = "msk-configuration-example"
  description        = "MSK configuration for ${data.aws_caller_identity.current.account_id}"
  server_properties = jsonencode({
    "default.replication.factor" = "3",
    "transaction.state.log.replication.factor" = "3",
    "transaction.state.log.min.isr" = "3",
  })
}

resource "aws_s3_bucket" "example" {
  bucket = "msk-s3-bucket-${data.aws_caller_identity.current.account_id}"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "msk-firehose-delivery-stream-${data.aws_caller_identity.current.account_id}"
  destination = "s3"

  kinesis_source_configuration {
    role_arn             = aws_iam_role.msk_service_role.arn
    stream_arn           = aws_kinesis_stream.example.arn
    processing_config {
      enabled = true
    }
  }

  s3_bucket_arn = aws_s3_bucket.example.arn

  tags = {
    Name = "msk-firehose-delivery-stream-${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_kinesis_stream" "example" {
  name        = "msk-kinesis-stream-${data.aws_caller_identity.current.account_id}"
  shard_count = 1
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "msk-cloudwatch-log-group-${data.aws_caller_identity.current.account_id}"
  retention_in_days = 30

  tags = {
    Name = "msk-cloudwatch-log-group-${data.aws_caller_identity.current.account_id}"
  }
}