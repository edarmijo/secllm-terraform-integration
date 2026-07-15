provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_analytics_application" "kinesis_app" {
  name = "my-kinesis-app"

  inputs {
    name = "cloudwatch-log-input"
    kinesis_stream = aws_kinesis_stream.log_stream.name
    schema = file("input_schema.json")
  }

  outputs {
    name = "firehose-output"
    firehose_destination = aws_firehose_delivery_stream.firehose_stream.name
  }
}

resource "aws_kinesis_stream" "log_stream" {
  name = "my-log-stream"
  retention_period = 7 * 24 * 60 * 60
}

resource "aws_firehose_delivery_stream" "firehose_stream" {
  name = "my-firehose-stream"
  destination_type = "S3"
  s3_configuration {
    bucket = "my-s3-bucket"
    prefix = "firehose-output"
  }
}

resource "aws_iam_role" "kinesis_app_role" {
  name = "kinesis-app-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "kinesisanalytics.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  managed_policy {
    name = "kinesis-app-policy"
    policy = file("iam_policy.json")
  }
}

resource "aws_kinesis_analytics_application_configuration" "kinesis_app_config" {
  application_name = aws_kinesis_analytics_application.kinesis_app.name
  service_account_name = aws_iam_role.kinesis_app_role.name
}