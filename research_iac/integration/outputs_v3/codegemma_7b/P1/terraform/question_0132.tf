provider "aws" {
  region = "us-east-1"
}

resource "aws_memcached_cluster" "example" {
  name = "my-memcached-cluster"

  node_count = 3

  subnet_ids = ["subnet-12345678", "subnet-98765432", "subnet-fedcba90"]

  security_group_ids = ["sg-12345678"]

  auto_scaling_enabled = true

  engine_version = "1.6.6"

  maintenance_window = "sun:00:00-sun:01:00"
}

resource "aws_iam_role" "memcached_access" {
  name = "memcached-access-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "memcached.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "memcached_access_policy" {
  name = "memcached-access-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "memcached:CreateCluster",
        "memcached:DeleteCluster",
        "memcached:UpdateCluster",
        "memcached:DescribeClusters",
        "memcached:ListClusters"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "memcached_access_policy_attachment" {
  role = aws_iam_role.memcached_access.name
  policy_arn = aws_iam_policy.memcached_access_policy.arn
}

resource "aws_instance_profile" "memcached_access_profile" {
  name = "memcached-access-profile"

  role = aws_iam_role.memcached_access.name
}