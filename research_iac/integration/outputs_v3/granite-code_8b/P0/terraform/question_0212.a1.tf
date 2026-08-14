provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  cluster_name    = "example-cluster"
  kafka_version   = "2.4.1"
  number_of_nodes = 3

  broker_node_group_info {
    instance_type = "kafka.t3.small"
    client_subnets = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    security_groups  = [aws_security_group.example.id]
  }

  encryption_in_transit {
    client_broker = "TLS_PLAINTEXT"
    in_cluster    = true
  }

  open_monitoring {
    producers {
      cloudwatch_logs {
        enabled = true
        log_group_arn = aws_cloudwatch_log_group.example.arn
      }
    }
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name           = "example-delivery-stream"
  destination    = "s3"
  s3_configuration {
    bucket_arn = aws_s3_bucket.example.arn
    role_arn   = aws_iam_role.example.arn
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name = "/aws/msk/${aws_msk_cluster.example.cluster_name}"
}

resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.example.arn}/*",
      "Action": "s3:PutObject"
    }
  ]
}
EOF
}