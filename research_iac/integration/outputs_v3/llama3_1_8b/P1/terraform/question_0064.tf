provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "example-firehose-delivery-stream"
  destination = "opensearch"

  opensearch_destination {
    domain_arn      = aws_opensearch_domain.example.domain_arn
    index_name       = "my-index"
    role_arn         = aws_iam_role.firehose-role.arn
    compression_format = "GZIP"
  }
}

resource "aws_opensearch_domain" "example" {
  domain_name           = "example-domain"
  engine_version        = "OpenSearch_1.2"
  cluster_config {
    instance_type = "r5.large.search"
  }

  vpc_options {
    security_group_ids = [aws_security_group.example.id]
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 443"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "firehose-role" {
  name        = "example-firehose-role"
  description = "For Kinesis Firehose to access OpenSearch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "firehose-policy" {
  name        = "example-firehose-policy"
  description = "Policy for Kinesis Firehose to access OpenSearch"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "opensearch:PutRecord",
          "opensearch:GetIndex",
        ]
        Effect   = "Allow"
        Resource = aws_opensearch_domain.example.domain_arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose-attachment" {
  role       = aws_iam_role.firehose-role.name
  policy_arn = aws_iam_policy.firehose-policy.arn
}