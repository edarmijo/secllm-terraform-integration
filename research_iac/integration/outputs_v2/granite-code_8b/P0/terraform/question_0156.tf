resource "aws_lambda_function" "test_lambda" {
  function_name = "test_lambda"
  handler       = "index.handler"
  role          = aws_iam_role.test_lambda_role.arn
  runtime       = "nodejs12.x"

  source_code_hash = filebase64sha256("${path.module}/lambda_function/index.js")
}

resource "aws_iam_role" "test_lambda_role" {
  name = "test_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "test_lambda_policy" {
  name   = "test_lambda_policy"
  role   = aws_iam_role.test_lambda_role.id
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
        Resource = "*"
      },
    ]
  })
}