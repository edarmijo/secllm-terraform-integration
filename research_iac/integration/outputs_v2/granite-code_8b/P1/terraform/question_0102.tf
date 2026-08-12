provider "aws" {
  region = var.region
}

resource "aws_iam_role" "example" {
  name               = "example"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = "example"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_eks_cluster" "example" {
  name     = "example"
  role_arn = aws_iam_role.example.arn

  subnet_ids = [aws_subnet.example.id]

  endpoint_private_access = false
  endpoint_public_access  = true

  tags = {
    Name = "example"
  }
}

resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "example-ng"
  subnet_ids      = [aws_subnet.example.id]

  instance_types = ["t3.small"]

  tags = {
    Name = "example-ng"
  }
}