provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "neptune_access" {
  name = "neptune-access-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "neptune.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "neptune_access_policy" {
  name = "neptune-access-policy"
  role = aws_iam_role.neptune_access.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "neptune:*",
        "s3:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_neptune_cluster" "cluster" {
  cluster_identifier = "my-neptune-cluster"
  engine = "neptune"
  engine_version = "1.3.0"
  vpc_security_group_ids = [aws_security_group.neptune_security_group.id]
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  iam_role_arn = aws_iam_role.neptune_access.arn
}

resource "aws_security_group" "neptune_security_group" {
  name = "neptune-security-group"

  ingress {
    from_port = 8182
    to_port = 8182
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}