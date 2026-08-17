provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  cluster_name           = "example"
  number_of_broker_nodes = 3
  kafka_version          = "KAFKA_2_1_1"
  broker_node_group_info {
    instance_type  = "kafka.msk-1.1.0-beta.1-ubuntu-18.04"
    ebs_volume_size = 100
    client_subnets  = ["subnet-12345678"]
    security_groups = ["sg-12345678"]
  }
  logging_info {
    broker_logs {
      firehose {
        delivery_stream {
          arn = "arn:aws:firehose:us-east-1:123456789012:deliverystream/example"
        }
      }
    }
  }
}