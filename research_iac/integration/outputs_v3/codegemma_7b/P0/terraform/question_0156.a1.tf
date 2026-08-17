provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "test_lambda_role" {
  name = "test_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "test_lambda_policy" {
  name = "test_lambda_policy"
  role = aws_iam_role.test_lambda_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeImages",
        "ec2:CreateImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "test_lambda" {
  function_name = "test_lambda"
  runtime = "python3.9"
  handler = "index.handler"
  role = aws_iam_role.test_lambda_role.arn

  environment {
    variables = {
      TEST_VARIABLE = "test_value"
    }
  }

  # Corrected code source
  source_code_bucket = "your-bucket-name"
  source_code_bucket_key = "lambda_code.zip"
}

resource "aws_event_rule" "image_created_rule" {
  name = "image_created_rule"
  event_source_arn = aws_lambda_function.test_lambda.arn

  filter {
    pattern = "image-created"
  }
}

resource "aws_lambda_permission" "image_created_permission" {
  function_name = aws_lambda_function.test_lambda.function_name
  source_account = aws_event_rule.image_created_rule.event_source_account_id
  action = "lambda:InvokeFunction"
}