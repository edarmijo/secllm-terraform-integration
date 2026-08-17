provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "test_lambda" {
  function_name = "test_lambda"
  runtime = "nodejs12.x"
  handler = "index.handler"
  source_code_hash = filebase64sha256("lambda_function.js")
  role = aws_iam_role.test_lambda_role.arn
}

resource "aws_iam_role" "test_lambda_role" {
  name = "test_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "test_lambda_policy" {
  name = "test_lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateImage",
          "ec2:DescribeImages",
          "ec2:DeleteImage"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test_lambda_policy_attachment" {
  role       = aws_iam_role.test_lambda_role.name
  policy_arn = aws_iam_policy.test_lambda_policy.arn
}

resource "aws_ec2_image" "test_image" {
  name = "test_image"
  description = "Test image"
  instance_id = aws_instance.test_instance.id
}

resource "aws_instance" "test_instance" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}