provider "aws" {
  region = "us-east1"
}

resource "aws_msk_cluster" "example" {
  name = "my-msk-cluster"

  kafka_version = "2.8.1"

  broker_node_group_info {
    instance_type = "kafka.t3.medium"
    desired_instance_count = 3
    client_subnets = ["subnet-12345678", "subnet-98765432", "subnet-fedcba90"]
    security_groups = ["sg-12345678", "sg-98765432", "sg-fedcba90"]
  }

  logging {
    broker {
      enabled = true
      destination_name = aws_kinesis_firehose_delivery_stream.example.name
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name = "my-firehose-stream"

  destination {
    type = "s3"
    s3_configuration {
      bucket = "my-s3-bucket"
      prefix = "msk-logs"
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose-role"

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

  managed_policy {
    name = "firehose-policy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:AbortMultipartUpload"
      ],
      "Resource": [
        "arn:aws:s3:::my-s3-bucket/*"
      ]
    }
  ]
}
EOF
  }
}

resource "aws_iam_role_policy_attachment" "firehose_role_policy" {
  role = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_managed_policy.firehose_policy.arn
}