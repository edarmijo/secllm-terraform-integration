provider "aws" {
  region = var.region
}

data "aws_region" "current" {}

resource "aws_iam_group" "example" {
  name = "example-group"
}

resource "aws_iam_group_policy_attachment" "example" {
  group      = aws_iam_group.example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}