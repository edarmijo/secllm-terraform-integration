provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "test_lambda_execution_role" {
  name               = "test_lambda_execution_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "test_lambda_execution_policy" {
  name        = "test_lambda_execution_policy"
  description = "Policy for test lambda execution role"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:CreateTags",
        "ec2:DescribeInstances",
        "ec2:RunInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test_lambda_execution_policy_attachment" {
  role       = aws_iam_role.test_lambda_execution_role.name
  policy_arn = aws_iam_policy.test_lambda_execution_policy.arn
}

resource "aws_lambda_function" "test_lambda" {
  filename         = "test_lambda.zip"
  function_name    = "test_lambda"
  role             = aws_iam_role.test_lambda_execution_role.arn
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  source_code_hash = filebase64sha256("test_lambda.zip")
}

resource "aws_ec2_image" "example" {
  name             = "example-image"
  image_location   = "s3://mybucket/example-image.img"
  source_ami_id    = "ami-12345678"
  source_ami_name  = "example-image"
  source_ami_owner = "self"
}

resource "aws_lambda_permission" "test_lambda_execution_permission" {
  statement_id  = "AllowExecutionFromEC2Image"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "ec2.amazonaws.com"
}