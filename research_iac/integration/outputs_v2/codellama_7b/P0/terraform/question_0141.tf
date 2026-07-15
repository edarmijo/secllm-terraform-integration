provider "aws" {
  region = "us-east-1"
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier = "my-redshift-cluster"
  node_type          = "dc2.large"
  database_name      = "mydb"
  master_username    = "foo"
  master_password    = "bar"
  number_of_nodes    = 2
}

resource "aws_redshift_endpoint_authorization" "example" {
  account_id   = "012345678910"
  cluster_name = aws_redshift_cluster.example.cluster_identifier
}