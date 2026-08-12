provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "my_lambda_function"
  runtime = "python3.9"
  handler = "lambda_handler.lambda_handler"
  role = aws_iam_role.my_role.arn

  trigger {
    type = "schedule"
    schedule = "cron(0,15,30,45 * * ? *)"
  }

  code {
    zip_file = "lambda_code.zip"
  }
}

resource "aws_iam_role" "my_role" {
  name = "my_lambda_role"

  assume_role_policy {
    statement {
      effect = "Allow"
      principal {
        service = "lambda.amazonaws.com"
      }
      action = "sts:AssumeRole"
    }
  }

  policy {
    name = "my_lambda_policy"
    policy_document = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "arn:aws:logs:*:*:*"
        }
      ]
    })
  }
}