provider "aws" {
  region = "us-east-1"
}

resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier = "my-redshift-cluster"
  database_name       = "mydatabase"
  master_username     = "myuser"
  master_password     = "mypassword"
  node_type           = "dc2.large"
  num_nodes           = 2
}

resource "aws_redshift_endpoint_authorization" "endpoint_authorization" {
  account_with_access = "012345678910"
  cluster_identifier = aws_redshift_cluster.redshift_cluster.cluster_identifier
}