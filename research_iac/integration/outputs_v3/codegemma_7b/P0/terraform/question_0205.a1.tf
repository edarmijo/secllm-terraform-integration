provider "aws" {
  region = "us-east1"
}

resource "aws_msk_cluster" "example" {
  name                = "example-cluster"
  cluster_name        = "example-cluster"
  kafka_version        = "2.8.1"
  number_of_broker_nodes = 2
  broker_node_group_info {
    instance_type = "kafka.t3.medium"
    desired_instance_count = 2
  }
  logging {
    broker {
      enabled = true
      destination_firehose_name = aws_kinesis_firehose_delivery_stream.example.name
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name = "example-firehose-stream"
  destination {
    type = "s3"
    s3_configuration {
      bucket = "example-bucket"
      prefix = "msk-logs"
    }
  }
}