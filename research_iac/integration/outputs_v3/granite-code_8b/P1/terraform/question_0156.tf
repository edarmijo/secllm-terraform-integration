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

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "ec2:DescribeImages"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "path/to/lambda/code"
  output_path = "path/to/lambda/code.zip"
}