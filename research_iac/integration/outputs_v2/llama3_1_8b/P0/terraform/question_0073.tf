provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "kinesis_analytics_app_role" {
  name        = "KinesisAnalyticsAppRole"
  description = "Execution role for Kinesis Analytics Application"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kinesisanalytics.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "kinesis_analytics_app_policy" {
  name        = "KinesisAnalyticsAppPolicy"
  description = "Policy for Kinesis Analytics Application"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:GetLogEvents",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = aws_cloudwatch_log_group.kinesis_analytics_app.arn
      },
      {
        Action = [
          "kinesis:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kinesis_analytics_app_attach" {
  role       = aws_iam_role.kinesis_analytics_app_role.name
  policy_arn = aws_iam_policy.kinesis_analytics_app_policy.arn
}

resource "aws_cloudwatch_log_group" "kinesis_analytics_app" {
  name              = "KinesisAnalyticsAppLogGroup"
  retention_in_days = 14
}

resource "aws_kinesisanalyticsv2_application" "example" {
  name        = "ExampleApplication"
  environment = "DEV"

  runtime_environment = "SERVERLESS"

  application_configuration {
    application_code_config {
      code_content {
        data_interval = 1000
        content       = filebase64("path/to/your/app/code")
      }
    }

    flink_application_configuration {
      parallelism_configuration {
        instance_type = "KINESISANALYTICS.M5D-large"
      }
    }
  }
}

resource "aws_kinesisanalyticsv2_input" "example" {
  name_prefix       = "ExampleInput"
  application_name  = aws_kinesisanalyticsv2_application.example.name
  current_database_name = "default"

  kinesis_stream_input {
    resource_arn = aws_kinesis_stream.example.arn

    role_arn      = aws_iam_role.kinesis_analytics_app_role.arn
  }
}

resource "aws_kinesisanalyticsv2_output" "example" {
  name_prefix       = "ExampleOutput"
  application_name  = aws_kinesisanalyticsv2_application.example.name
  current_database_name = "default"

  cloud_watch_logs_output {
    resource_arn = aws_cloudwatch_log_group.kinesis_analytics_app.arn

    role_arn      = aws_iam_role.kinesis_analytics_app_role.arn
  }
}