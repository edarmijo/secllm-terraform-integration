provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "redshift_role" {
  name        = "RedshiftRole"
  description = "IAM role for Redshift cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "redshift_policy" {
  name   = "RedshiftPolicy"
  role   = aws_iam_role.redshift_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::my-bucket/*"
      },
    ]
  })
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier = "example"
  node_type          = "dc2.large"
  database_name      = "mydb"
  master_username    = "foo"
  master_password    = var.master_password
  vpc_security_group_ids = [aws_security_group.redshift_sg.id]
}

resource "aws_security_group" "redshift_sg" {
  name        = "RedshiftSG"
  description = "Security group for Redshift cluster"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}