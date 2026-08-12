provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_kinesisanalytics_application" "example" {
  name        = "example-kinesis-analytics"
  environment = "DEV"

  runtime_configuration {
    type_version = "1.0-2908"
    property_groups {
      property_group_name = "MyPropertyGroup"
      properties {
        key   = "my.property.key"
        value = "my.property.value"
      }
    }
  }
}

resource "aws_kinesisanalytics_application_input" "example" {
  application_name = aws_kinesisanalytics_application.example.name
  name             = "example-input"

  kinesis_stream_input {
    resource_arn = aws_kinesis_stream.example.arn

    role_arn       = aws_iam_role.analytics-execution-role.arn
    input_schema {
      record_format_type = "JSON"
      mapping_parameters = jsonencode({
        json_mapping_parameters = {
          record-row-delimiter = "\n"
        }
      })
    }
  }
}

resource "aws_kinesis_stream" "example" {
  name             = "example-stream"
  shard_count      = 1
  retention_period = 24

  encryption_config {
    key_type = "KMS"

    key_arn = aws_kms_key.example.arn
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/kinesis-analytics/example-kinesis-analytics"
  retention_in_days = 7
}

resource "aws_kinesisanalytics_application_output" "example" {
  application_name = aws_kinesisanalytics_application.example.name
  name             = "example-output"

  cloud_watch_log_stream {
    destination_arn = aws_cloudwatch_log_group.example.arn

    role_arn       = aws_iam_role.analytics-execution-role.arn
  }
}

resource "aws_iam_role" "analytics-execution-role" {
  name        = "kinesis-analytics-execution-role"
  description = "Execution role for Kinesis Analytics"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kinesisanalytics.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "analytics-execution-role-policy" {
  name   = "kinesis-analytics-execution-role-policy"
  role   = aws_iam_role.analytics-execution-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutRecord",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "kinesis-analytics-execution-role-policy" {
  name   = "kinesis-analytics-execution-role-policy"
  role   = aws_iam_role.analytics-execution-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:SubscribeToShard",
        ]
        Effect   = "Allow"
        Resource = aws_kinesis_stream.example.arn
      },
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch-logs-policy" {
  name   = "cloudwatch-logs-policy"
  role   = aws_iam_role.analytics-execution-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutRecord",
        ]
        Effect   = "Allow"
        Resource = aws_cloudwatch_log_group.example.arn
      },
    ]
  })
}

resource "aws_kms_key" "example" {
  description             = "KMS key for Kinesis Analytics"
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Action    = "kms:DescribeKey"
        Resource  = "*"
        Principal = {
          Service = "iam.amazonaws.com"
        }
      },
      {
        Sid       = "Allow use of the key for Kinesis Analytics"
        Effect    = "Allow"
        Action    = [
          "kinesis:Encrypt",
          "kinesis:Decrypt",
        ]
        Resource  = aws_kinesis_stream.example.arn
        Condition  = {
          ArnEquals = {
            kms:EncryptionKeyArn = aws_kms_key.example.arn
          }
        }
      },
    ]
  })
}