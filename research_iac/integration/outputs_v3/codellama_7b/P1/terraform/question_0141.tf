provider "aws" {
  region = "us-east-1"
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier = "example"
  node_type          = "dc2.large"
  database_name      = "mydb"
  master_username    = "foo"
  master_password    = var.master_password
  port               = 5439
  vpc_security_group_ids = [aws_security_group.redshift.id]
}

resource "aws_security_group" "redshift" {
  name        = "redshift-sg"
  description = "RedShift security group"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_iam_role" "redshift" {
  name               = "RedShiftRole"
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

resource "aws_iam_role_policy" "redshift" {
  name   = "RedShiftPolicy"
  role   = aws_iam_role.redshift.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::mybucket/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "redshift" {
  role       = aws_iam_role.redshift.name
  policy_arn = aws_iam_policy.redshift.arn
}

resource "aws_iam_policy" "redshift" {
  name        = "RedShiftPolicy"
  description = "RedShift policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::mybucket/*"
    }
  ]
}
EOF
}