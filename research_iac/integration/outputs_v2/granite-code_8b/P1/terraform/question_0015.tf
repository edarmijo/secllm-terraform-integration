# Configure production and staging Elastic Beanstalk environments with a respective db_instance from RDS

provider "aws" {
  region = var.region
}

resource "aws_db_instance" "prod_db" {
  identifier           = "prod_db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true

  # ... (other configuration options)
}

resource "aws_db_instance" "staging_db" {
  identifier           = "staging_db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true

  # ... (other configuration options)
}

resource "aws_iam_role" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  # ... (other configuration options)
}