provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  name        = "example-msk-cluster"
  kafka_version = "2.7.0"
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type = "kafka.m5.large"
    ebs_volume_size = 100
    client_subnets = ["subnet-12345678"]
    security_groups = [aws_security_group.example.id]
  }
  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.example.name
      }
    }
  }
}

resource "aws_security_group" "example" {
  name        = "example-msk-cluster-sg"
  description = "Security group for example MSK cluster"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "example-msk-cluster-logs"
  retention_in_days = 14
}