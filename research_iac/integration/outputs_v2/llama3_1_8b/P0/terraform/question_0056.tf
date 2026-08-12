provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "kinesis_stream_exec_role" {
  name        = "KinesisStreamExecutionRole"
  description = "Execution role for the Kinesis stream"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kinesis.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "kinesis_stream_exec_policy" {
  name        = "KinesisStreamExecutionPolicy"
  description = "Execution policy for the Kinesis stream"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:PutRecord",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_exec_policy_to_role" {
  role       = aws_iam_role.kinesis_stream_exec_role.name
  policy_arn = aws_iam_policy.kinesis_stream_exec_policy.arn
}

resource "aws_kinesis_stream" "example_stream" {
  name        = "ExampleStream"
  shard_count = 1

  server_side_encryption {
    enabled = true
  }
}