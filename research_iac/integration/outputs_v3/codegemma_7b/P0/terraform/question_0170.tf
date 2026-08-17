provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "dax_subnet_group_role" {
  name = "dax-subnet-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "dax.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "dax_subnet_group_policy" {
  name = "dax-subnet-group-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dax_subnet_group_role_policy" {
  role       = aws_iam_role.dax_subnet_group_role.name
  policy_arn = aws_iam_policy.dax_subnet_group_policy.arn
}

resource "aws_dax_subnet_group" "dax_subnet_group" {
  name = "custom-dax-subnet-group"

  subnet_ids = var.subnet_ids
  role_arn   = aws_iam_role.dax_subnet_group_role.arn
}