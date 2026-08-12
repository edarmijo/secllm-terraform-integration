provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "redshift_role" {
  name        = "RedshiftRole"
  description = "IAM role for Redshift cluster"

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
  cluster_identifier = "example-redshift-cluster"
  node_type          = "dc2.large"
  database_name      = "mydb"
  master_username    = "foo"
  master_password    = "bar"
}

resource "aws_iam_role_policy_attachment" "redshift-policy-attachment" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}

resource "aws_redshift_cluster_parameter_group" "example" {
  name        = "example-redshift-cluster-parameters"
  family      = "redshift-1.0"
  description = "Example Redshift cluster parameter group"

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }
}