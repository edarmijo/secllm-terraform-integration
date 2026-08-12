provider "aws" {
  region = var.region
}

resource "aws_msk_cluster" "example" {
  cluster_name    = var.cluster_name
  number_of_nodes = var.number_of_nodes

  broker_node_group_info {
    instance_type   = var.instance_type
    client_subnets  = var.client_subnets
    security_groups = var.security_groups
  }

  configuration_info {
    arn      = var.configuration_arn
    revision = var.revision
  }

  open_monitoring {
   prometheus {}
  }
}