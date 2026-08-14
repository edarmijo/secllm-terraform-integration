provider "aws" {
  region = "us-east2"
}

resource "aws_msk_cluster" "example" {
  name                   = "example"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "m5.large"
    client_subnets  = ["subnet-12345678", "subnet-87654321"]
    security_groups  = ["sg-12345678"]
  }

  configuration_info {
    arn      = "arn:aws:secretsmanager:us-east2:123456789012:secret:msk-cluster-config-123456"
    revision = 1
  }

  open_monitoring {
    producers = [
      {
        name           = "CloudWatchLogs"
        destination_arn = "arn:aws:logs:us-east2:123456789012:log-group:/aws/msk/example/clusters/*"
      },
    ]
  }
}