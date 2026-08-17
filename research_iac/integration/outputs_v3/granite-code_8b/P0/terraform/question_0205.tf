provider "aws" {
  region = "us-east1"
}

resource "aws_msk_cluster" "example" {
  cluster_name    = "example-cluster"
  kafka_version   = "2.2.0"
  number_of_nodes = 3

  broker_node_group_info {
    instance_type = "m5.large"
    client_subnets = [
      "subnet-12345678",
      "subnet-87654321",
    ]
    security_groups = [
      "sg-12345678",
    ]
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = "example-log-group"
      }
      firehose {
        enabled    = true
        delivery_stream = "example-delivery-stream"
      }
    }
  }
}