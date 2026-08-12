provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eks_role" {
  name = "example-role"

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

resource "aws_iam_role_policy_attachment" "eks_role_policy_attachment" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "example" {
  name                = "example"
  role_arn            = aws_iam_role.eks_role.arn
  version             = "1.24"
  subnet_ids          = ["subnet-12345678"]
  vpc_config {
    security_group_ids = ["sg-12345678"]
  }
  endpoint_private_access = false
  endpoint_public_access  = true
}