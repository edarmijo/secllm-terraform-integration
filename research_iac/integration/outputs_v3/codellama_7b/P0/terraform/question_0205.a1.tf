provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  cluster_name           = "example"
  number_of_broker_nodes = 3
  kafka_version          = "2.8.0"
  broker_node_group_info {
    instance_type  = "kafka.msk.t3.medium"
    ebs_volume_size = 100
    client_subnets = ["subnet-0123456789abcdef0"]
    security_groups = ["sg-0123456789abcdef0"]
  }
  logging_info {
    broker_logs {
      firehose {
        delivery_stream {
          name = "example-firehose"
        }
      }
    }
  }
}