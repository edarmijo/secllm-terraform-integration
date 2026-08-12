provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "redshift_role" {
  name               = "redshift_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier           = "example-cluster"
  node_type                    = "ds2.xlarge"
  master_username              = "foo"
  master_password              = "bar"
  skip_final_snapshot          = true
  automated_snapshot_start_time = "08:00"

 iam_roles = [
    aws_iam_role.redshift_role.name,
  ]
}