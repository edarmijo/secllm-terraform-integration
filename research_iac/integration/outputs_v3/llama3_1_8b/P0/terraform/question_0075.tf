# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Create an IAM role for Kendra
resource "aws_iam_role" "kendra_service_role" {
  name        = "KendraServiceRole"
  description = "IAM role for Amazon Kendra"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kendra.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the necessary policies to the IAM role
resource "aws_iam_policy" "kendra_service_policy" {
  name        = "KendraServicePolicy"
  description = "IAM policy for Amazon Kendra"

  policy      = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kendra_service_attach" {
  role       = aws_iam_role.kendra_service_role.name
  policy_arn = aws_iam_policy.kendra_service_policy.arn
}

# Create a Kendra data source resource with URL Exclusion and Inclusion Patterns
resource "aws_kendra_data_source" "example" {
  name             = "ExampleDataSource"
  description      = "An example data source for Amazon Kendra"
  type             = "S3"
  s3_configuration {
    bucket_name       = "example-bucket"
    index_name        = "example-index"
    ingestion_role_arn = aws_iam_role.kendra_service_role.arn
  }

  url_configuration {
    enabled          = true
    exclusion_patterns = ["exclusion-pattern-1", "exclusion-pattern-2"]
    inclusion_patterns = ["inclusion-pattern-1", "inclusion-pattern-2"]
  }
}