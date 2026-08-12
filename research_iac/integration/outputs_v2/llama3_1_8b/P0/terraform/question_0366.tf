provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lightsail_db_role" {
  name        = "LightsailDBRole"
  description = "Allows Lightsail to manage the RDS instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lightsail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lightsail_db_policy" {
  name        = "LightsailDBPolicy"
  description = "Allows Lightsail to manage the RDS instance"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "rds:StartDBInstance",
          "rds:StopDBInstance",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lightsail_db_attach" {
  role       = aws_iam_role.lightsail_db_role.name
  policy_arn = aws_iam_policy.lightsail_db_policy.arn
}

resource "aws_lightsail_database" "example" {
  name                  = "example"
  username              = "exampleuser"
  password              = "examplepassword"
  master_user_password  = "examplepassword"
  backup_retention_period = 1

  depends_on = [aws_iam_role_policy_attachment.lightsail_db_attach]
}