provider "aws" {
  region = var.region
}

resource "aws_kinesisanalytics_application" "example" {
  name                = "example-app"
  runtime_environment = "FLINK-1_6"

  service_execution_role = aws_iam_role.service_execution.arn

  inputs {
    name           = "example-stream"
    kinesis_stream = aws_kinesis_stream.example.arn
    starting_position = "LATEST"
  }

  outputs {
    name        = "example-output"
    destination = "cloudwatch_log_stream"

    cloudwatch_log_stream {
      log_group_name  = aws_cloudwatch_log_group.example.name
      role_arn         = aws_iam_role.firehose_delivery.arn
    }
  }
}