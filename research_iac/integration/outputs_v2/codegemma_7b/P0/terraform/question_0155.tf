provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "my_lambda_function"
  runtime = "python3.9"
  handler = "lambda_handler.lambda_handler"
  role = aws_iam_role.my_role.arn

  environment {
    variables = {
      "SCHEDULE_INTERVAL": "15"
    }
  }

  trigger {
    type = "schedule"
    schedule = "cron(0,15,30,45 * * ? *)"
  }
}

resource "aws_iam_role" "my_role" {
  name = "my_lambda_role"

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

  policy {
    name = "my_lambda_policy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
  }
}