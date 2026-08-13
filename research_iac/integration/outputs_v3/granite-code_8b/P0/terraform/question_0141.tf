provider "aws" {
  region = "us-east-1"
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier           = "example-cluster"
  node_type                    = "ds2.xl"
  master_username              = "foo"
  master_password              = "bar"
  skip_final_snapshot          = true
  automated_snapshot_start_time = "09:00"

  # ... (other settings)
}

resource "aws_redshift_endpoint_authorization" "example" {
  account                      = "012345678910"
  cluster_identifier           = aws_redshift_cluster.example.id
}