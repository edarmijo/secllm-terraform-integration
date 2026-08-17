resource "aws_lambda_function" "test_lambda" {
  function_name = "test_lambda"
  runtime = "python3.8"
  handler = "index.handler"
  source_code_hash = filebase64sha256("lambda_function.py")
  role = aws_iam_role.lambda_exec_role.arn
  environment {
    variables = {
      EC2_IMAGE_ID = aws_instance.test_image.id
    }
  }
}

resource "aws_instance" "test_image" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
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

provider "aws" {
  region = "us-east-1"
}