provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "example_role" {
  name = "example_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "example_role_policy_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  depends_on = [aws_iam_role.example_role]
}

resource "aws_eks_cluster" "example_cluster" {
  name                = "example"
  version             = "1.24"
  role_arn            = aws_iam_role.example_role.arn
  subnet_ids          = ["subnet-12345678"]
  vpc_config {
    security_group_ids = ["sg-12345678"]
  }

  endpoint_private_access = false
  endpoint_public_access  = true
}