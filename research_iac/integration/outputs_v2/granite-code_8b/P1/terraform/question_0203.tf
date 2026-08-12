provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "example-log-group"
  retention_in_days = 30
}

resource "aws_msk_cluster" "example" {
  cluster_name    = "example-cluster"
  kafka_version   = "2.1.1"
  number_of_nodes = 3

  logging {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.example.arn
  }
}