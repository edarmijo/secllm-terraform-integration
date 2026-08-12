provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_database" "example" {
  name          = "example-db"
  engine        = "mysql"
  version       = "5.7"
  skip_final_snapshot = true

  master_arn = aws_iam_role.master.arn

  backup {
    enabled      = true
    retention    = 7
    rotation_day = 1
  }
}

resource "aws_lightsail_instance" "example" {
  name            = "example-instance"
  region          = "us-east-1"
  availability_zone = "us-east-1a"

  blueprint_id    = "string" # replace with actual blueprint ID
  bundle_id       = "string" # replace with actual bundle ID

  password = "string" # replace with actual password

  public_key = "string" # replace with actual public key

  tags = {
    Name = "example- lightsail-instance"
  }
}

resource "aws_iam_role" "master" {
  name = "example-lightsail-master-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lightsail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  inline_policy {
    name = "example-lightsail-master-inline-policy"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lightsail:CreateDatabase",
        "lightsail:DeleteDatabase",
        "lightsail:GetDatabase",
        "lightsail:UpdateDatabase"
      ],
      "Resource": "*"
    }
  ]
}
EOF

  }
}