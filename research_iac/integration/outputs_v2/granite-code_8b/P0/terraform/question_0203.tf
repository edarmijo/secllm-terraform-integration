provider "aws" {
  region = "us-east1"
}

resource "aws_msk_cluster" "example" {
  name               = "example-cluster"
  number_of_brokers  = 3
  broker_node_group {
    instance_type = "kafka.m5.large"
    client_subnets = [
      "subnet-12345678",
      "subnet-87654321",
    ]
    security_groups = ["sg-12345678"]
  }

  logging {
    cloudwatch_log_group {
      name           = "example-cluster-logs"
      log_group_arn  = aws_cloudwatch_log_group.example.arn
    }
  }
}