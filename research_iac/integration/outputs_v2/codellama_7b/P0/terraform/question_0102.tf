provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "example" {
  name               = "example"
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

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}

resource "aws_eks_cluster" "example" {
  name            = "example"
  role_arn        = aws_iam_role.example.arn
  endpoint_private_access = false
  endpoint_public_access = true

  vpc_config {
    subnet_ids = [aws_subnet.example.id]
  }
}

resource "aws_subnet" "example" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.example.id
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}