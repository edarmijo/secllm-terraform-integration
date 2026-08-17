provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  cluster_name           = "example"
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type  = "kafka.msk-1.1.0-beta.1-ubuntu-18.04"
    ebs_volume_size = 100
  }
  logging_info {
    firehose {
      delivery_stream {
        arn = "arn:aws:firehose:us-east-1:123456789012:deliverystream/example"
      }
    }
  }
}