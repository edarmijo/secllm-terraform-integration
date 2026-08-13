provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesisanalyticsv2_application" "example" {
  name                   = "example-app"
  runtime_environment    = "FLINK"
  service_execution_role = aws_iam_role.example.arn
}

resource "aws_cloudwatch_log_stream" "example" {
  log_group_name = "/aws/lambda/example-function"
  name           = "example-log-stream"
}

resource "aws_kinesisanalyticsv2_application_inputs" "example" {
  application_name    = aws_kinesisanalyticsv2_application.example.name
  input_parallelism   = 1
  input_starting_position = "LATEST"
  input_type          = "CLOUDWATCH_LOG"
  name                = "example-input"
}

resource "aws_kinesisanalyticsv2_application_outputs" "example" {
  application_name    = aws_kinesisanalyticsv2_application.example.name
  destination_id      = "example-destination"
  output_type         = "KINESIS_STREAM"
  name                = "example-output"
}

resource "aws_iam_role" "example" {
  name               = "example-role"
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