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

resource "aws_iam_role_policy_attachment" "test_lambda_policy" {
  role       = aws_iam_role.test_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "test_lambda" {
  function_name = "test_lambda"
  runtime      = "nodejs14.x"
  handler       = "index.handler"
  role          = aws_iam_role.test_lambda_role.arn

  trigger {
    type = "aws_ec2_image_created"
  }
}