provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  name                = "example-cluster"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type = "m5.large"
    client_subnets = ["subnet-12345678", "subnet-87654321"]
    security_groups    = ["sg-12345678"]
  }

  configuration_info {
    arn      = "arn:aws:kafka:us-east-1:123456789012:configuration/example-config-1234567890"
    revision = 1
  }

  encryption_in_transit {
    client_broker = "TLS_PLAINTEXT"
    in_cluster    = true
  }
}