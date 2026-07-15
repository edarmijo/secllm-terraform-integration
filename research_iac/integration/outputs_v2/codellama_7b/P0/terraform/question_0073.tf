provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesisanalyticsv2_application" "example" {
  name                   = "my-kinesis-analytics-app"
  service_execution_role = aws_iam_role.service_execution_role.arn
  create_timestamp       = timestamp()
}

resource "aws_iam_role" "service_execution_role" {
  name               = "my-kinesis-analytics-app-service-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "kinesisanalytics.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_stream" "example" {
  name           = "my-kinesis-analytics-app-log-stream"
  log_group_name = aws_cloudwatch_log_group.example.name
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "my-kinesis-analytics-app-log-group"
  retention_in_days = 14
}