provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_group" "example_group" {
  name = "ExampleGroup"
}

resource "aws_iam_group_policy_attachment" "example_attach" {
  group      = aws_iam_group.example_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}