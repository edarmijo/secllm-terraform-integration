resource "aws_iam_role_policy" "webapp_policy" {
  name        = "webapp-policy"
  role        = aws_iam_role.webapp_role.name
  description = "IAM policy for web application access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::my-webapp-bucket/*"
    },
    {
      "Action": [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:::my-webapp-table/*"
    }
  ]
}
EOF
}

resource "aws_db_subnet_group" "webapp_rds_sg" {
  name       = "webapp-rds-sg"
  subnet_ids = [aws_subnet.webapp_subnet1.id, aws_subnet.webapp_subnet2.id]
}

resource "aws_security_group" "webapp_rds_sg" {
  name        = "webapp-rds-sg"
  description = "Security group for web application RDS instance"
  vpc_id      = aws_vpc.webapp_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}