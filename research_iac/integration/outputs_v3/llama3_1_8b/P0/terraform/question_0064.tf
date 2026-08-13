provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "firehose_service_role" {
  name        = "FirehoseServiceRole"
  description = "Execution role for Firehose service"

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

resource "aws_iam_policy" "firehose_service_policy" {
  name        = "FirehoseServicePolicy"
  description = "Policy for Firehose service"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutRecord",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.example.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_service_attach" {
  role       = aws_iam_role.firehose_service_role.name
  policy_arn = aws_iam_policy.firehose_service_policy.arn
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "ExampleDeliveryStream"
  destination = "s3"

  s3_bucket_arn = aws_s3_bucket.example.arn

  kinesis_source_configuration {
    role_arn            = aws_iam_role.firehose_service_role.arn
    stream_arn          = aws_kinesis_stream.example.arn
    compression_format  = "GZIP"
    data_format_conversion_enabled = true
  }
}

resource "aws_s3_bucket" "example" {
  bucket        = "example-bucket"
  acl            = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_kinesis_stream" "example" {
  name        = "ExampleStream"
  shard_count = 1

  retention_period = "168h"

  encryption {
    key_type = "KMS"
    key_arn  = aws_kms_key.example.arn
  }
}

resource "aws_kms_key" "example" {
  description             = "Key for Kinesis Stream Encryption"
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Action    = ["kms:Encrypt", "kms:Decrypt"]
        Resource = "*"
        Principal = {
          Service = "iam.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_opensearch_domain" "example" {
  domain_name           = "example-domain"
  engine_version        = "OpenSearch_1.2"
  cluster_config {
    instance_type = "r5.large.search"
    instance_count = 1
  }

  vpc_options {
    security_group_ids = [aws_security_group.example.id]
    subnet_ids         = aws_subnet.example.*.id
  }
}

resource "aws_security_group" "example" {
  name        = "ExampleSecurityGroup"
  description = "Allow inbound traffic on port 443"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "example" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "ExampleSubnet-${count.index}"
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ExampleVPC"
  }
}