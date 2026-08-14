provider "aws" {
  region = var.region
}

resource "aws_security_group" "msk_security_group" {
  name   = "msk-security-group"
  description = "Security group for MSK cluster"

  ingress {
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with the actual CIDR block
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Replace with the actual CIDR block
  }

  tags = {
    Environment = "production"
  }
}

resource "aws_msk_cluster" "msk_cluster" {
  name = "msk-cluster"
  kafka_version = "2.4.1"
  number_of_broker_nodes = 3
  cluster_name = "msk-cluster"
  broker_node_group_info {
    instance_type = "m5.large"
    client_subnets = ["subnet-12345678", "subnet-87654321"] # Replace with the actual subnet IDs
    security_groups = [aws_security_group.msk_security_group.id]
  }

  encryption_in_transit {
    client_broker = "TLS"
    in_cluster    = true
  }

  open_monitoring {
    prometheus_exporters = ["GROUP"]
  }

  logging_info {
    broker_logs {
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.msk_log_group.arn
      log_type                 = "BrokerLogGroup"
    }

    broker_logs {
      s3_bucket_name           = aws_s3_bucket.msk_log_bucket.bucket
      log_type                 = "BrokerLogGroup"
    }

    broker_logs {
      firehose_arn             = aws_kinesis_firehose_delivery_stream.msk_firehose_stream.arn
      log_type                 = "FirehoseLogGroup"
    }
  }

  tags = {
    Environment = "production"
  }
}