provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_secretsmanager_secret" "msk_cluster" {
  name = "msk-cluster-credentials"
}

data "aws_secretsmanager_secret_version" "msk_cluster" {
  secret_id = data.aws_secretsmanager_secret.msk_cluster.id
}

data "aws_iam_policy_document" "msk_cluster" {
  statement {
    actions = [
      "kafka:CreateCluster",
      "kafka:DeleteCluster",
      "kafka:DescribeCluster",
      "kafka:ListClusters",
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords",
    ]
    resources = ["arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/*"]
  }
}

resource "aws_iam_role" "msk_cluster" {
  name        = "msk-cluster-execution-role"
  description = "Execution role for MSK cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kafka.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "msk_cluster" {
  name   = "msk-cluster-execution-policy"
  role   = aws_iam_role.msk_cluster.id
  policy = data.aws_iam_policy_document.msk_cluster.json
}

resource "aws_kafka_cluster" "example" {
  name        = "msk-cluster"
  kafka_version = "KAFKA_2_6_0"
  number_of_instance = 3
  instance_type = "kafka.m5.large"
  vpc_security_group_ids = [aws_security_group.msk_cluster.id]
  subnet_ids = [aws_subnet.msk_cluster.id]
  encryption_in_transit = "TLS"

  depends_on = [aws_iam_role_policy_attachment.msk_cluster]
}

resource "aws_security_group" "msk_cluster" {
  name        = "msk-cluster-sg"
  description = "Security group for MSK cluster"

  ingress {
    description = "Allow inbound traffic on port 9094"
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "msk-cluster-firehose"
  destination = "s3"

  kinesis_stream_source {
    kinesis_stream_arn = aws_kinesis_stream.example.arn
  }

  s3_bucket_destination {
    bucket_arn = aws_s3_bucket.example.arn
  }
}

resource "aws_kinesis_stream" "example" {
  name        = "msk-cluster-stream"
  shard_count = 1
}

resource "aws_s3_bucket" "example" {
  bucket = "msk-cluster-firehose-bucket"
  acl    = "private"
}

resource "aws_iam_role_policy_attachment" "msk_cluster" {
  role       = aws_iam_role.msk_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonMSKFullAccess"
}

resource "aws_iam_role_policy_attachment" "firehose" {
  role       = aws_iam_role.firehose.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonKinesisFirehoseServiceRole"
}

resource "aws_iam_role" "firehose" {
  name        = "firehose-execution-role"
  description = "Execution role for Kinesis Firehose"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}