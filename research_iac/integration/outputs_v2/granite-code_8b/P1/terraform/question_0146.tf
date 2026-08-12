provider "aws" {
  region = var.region
}

resource "aws_iam_role" "redshift_cluster_role" {
  name               = "redshift-cluster-role"
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
  node_type                    = "ds2.large"
  master_username              = "masteruser"
  master_password              = "MySuperSecretPassword"
  skip_final_snapshot          = true
  automated_snapshot_rotation  = false
  allow_version_upgrade        = false
  number_of_nodes               = 1
  publicly_accessible           = false
  encrypted                    = true
  enable_logging               = true
  logging_bucket               = "my-log-bucket"
  preferred_maintenance_window = "sun:05:00-sun:06:00"

  depends_on = [aws_iam_role.redshift_cluster_role]

  role_arn = aws_iam_role.redshift_cluster_role.arn
}