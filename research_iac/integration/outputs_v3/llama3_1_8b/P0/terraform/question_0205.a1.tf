provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kinesis_firehose_delivery_stream" "msk_firehose" {
  name        = "msk-firehose-stream"
  destination = "s3"

  s3_configuration {
    role_arn = aws_iam_role.msk_firehose.arn
    bucket_name = aws_s3_bucket.msk_firehose_bucket.id
    compression_format = "GZIP"
    role_arn = aws_iam_role.msk_firehose.arn
  }
}

resource "aws_s3_bucket" "msk_firehose_bucket" {
  bucket = "msk-firehose-bucket"
  acl    = "private"
}

resource "aws_iam_role" "msk_firehose" {
  name        = "msk-firehose-role"
  description = "Role for Kinesis Firehose to write to S3"

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

resource "aws_iam_role_policy" "msk_firehose_policy" {
  name   = "msk-firehose-policy"
  role   = aws_iam_role.msk_firehose.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        Effect = "Allow"
        Resource = aws_s3_bucket.msk_firehose_bucket.arn
      },
      {
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
        ]
        Effect = "Allow"
        Resource = aws_msk_cluster.msk_cluster.arn
      }
    ]
  })
}

resource "aws_msk_cluster" "msk_cluster" {
  cluster_name           = "msk-cluster"
  kafka_version          = "2.6.1"
  number_of_broker_nodes = 1
  broker_node_group_info {
    instance_type = "kafka.m5.large"
    instance_count = 3
    ebs_volume_size = 10
    ebs_volume_type = "gp2"
    ebs_volume_iops = 3000
  }
  vpc_security_group_ids  = [aws_security_group.msk_sg.id]
  subnet_ids              = [aws_subnet.msk_subnet.id]
  tags = {
    Name = "msk-cluster"
  }
}

resource "aws_security_group" "msk_sg" {
  name        = "msk-sg"
  description = "Security group for MSK cluster"
  vpc_id      = aws_vpc.msk_vpc.id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "msk_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "msk_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.msk_vpc.id
  availability_zone = "us-east-1a"
}

resource "aws_msk_configuration" "msk_config" {
  name = "msk-config"
  server_properties = jsonencode({
    "default.replication.factor" = 3
    "num.partitions" = 1
    "cleanup.policy" = "delete"
  })
}