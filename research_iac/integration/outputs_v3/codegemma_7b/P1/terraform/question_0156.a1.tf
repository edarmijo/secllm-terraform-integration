provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "test_lambda" {
  function_name = "test_lambda"
  runtime = "python3.8"
  handler = "index.handler"
  role = aws_iam_role.test_role.arn

  trigger {
    type = "aws_ec2_image_created"
  }

  environment {
    variables = {
      IMAGE_ID = aws_ec2_image.test_image.id
    }
  }
}

resource "aws_iam_role" "test_role" {
  name = "test_role"

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
    name = "test_policy"
    policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeImages",
        "lambda:InvokeFunction"
      ],
      "Resource": "*"
    }
  ]
}
EOF
  }
}

resource "aws_ec2_image" "test_image" {
  name = "test_image"
  image_location = "s3://test-bucket/test-image.img"
}