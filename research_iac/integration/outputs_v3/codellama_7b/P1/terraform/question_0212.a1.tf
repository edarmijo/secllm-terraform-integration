provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  cluster_name           = "example"
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type  = "kafka.m5.large"
    ebs_volume_size = 100
    client_subnets  = ["subnet-12345678"]
    security_groups = [aws_security_group.example.id]
  }
  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
    }
    encryption_at_rest {
      data_volume_kms_key_id = aws_kms_key.example.arn
    }
  }
  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }
}

resource "aws_security_group" "example" {
  name        = "example"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_kms_key" "example" {
  description             = "Example KMS key for MSK cluster"
  deletion_window_in_days = 7
}

resource "aws_s3_bucket" "example" {
  bucket        = "example-bucket"
  acl           = "private"
  force_destroy = true
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "example-firehose"
  destination = "s3"
  s3_configuration {
    role_arn   = aws_iam_role.example.arn
    bucket_arn = aws_s3_bucket.example.arn
  }
}

resource "aws_iam_role" "example" {
  name               = "example-firehose-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}