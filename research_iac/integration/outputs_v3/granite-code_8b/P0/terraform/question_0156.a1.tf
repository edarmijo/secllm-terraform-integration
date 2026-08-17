resource "aws_lambda_function" "test_lambda" {
  function_name = "test_lambda"
  handler        = "index.handler"
  role           = aws_iam_role.lambda_role.arn
  runtime        = "nodejs12.x"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      region = var.region
    }
  }

  event_source_mapping {
    event_source_arn = aws_ec2_image.test_image.arn
    function_name    = aws_lambda_function.test_lambda.function_name
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

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

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "path/to/lambda/function/code"
  output_path = "path/to/lambda/function/code.zip"
}

resource "aws_ec2_image" "test_image" {
  name           = "test_image"
  image_location = "path/to/image/location"
  architecture   = "x86_64"
  platform       = "linux"

  tags = {
    Name = "test_image"
  }
}