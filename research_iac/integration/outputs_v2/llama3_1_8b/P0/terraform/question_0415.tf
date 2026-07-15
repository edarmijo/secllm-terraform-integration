provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "rds-exec-role" {
  name        = "rds-exec-role"
  description = "Role for RDS to execute"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "rds-exec-policy" {
  name        = "rds-exec-policy"
  description = "Policy for RDS to execute"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds-exec-attach" {
  role       = aws_iam_role.rds-exec-role.name
  policy_arn = aws_iam_policy.rds-exec-policy.arn
}

resource "aws_db_instance" "example" {
  identifier           = "example-rds"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.rds-sg.id]
}

resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "Security group for RDS"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "example-io1" {
  identifier           = "example-rds-io1"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true
  storage_type         = "io1"
  iops                 = 1000

  vpc_security_group_ids = [aws_security_group.rds-sg.id]
}