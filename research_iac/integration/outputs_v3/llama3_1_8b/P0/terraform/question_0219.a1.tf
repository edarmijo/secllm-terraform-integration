provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "mysql_instance" {
  name        = "my-mysql-instance-role"
  description = "Role for MySQL instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "mysql_instance" {
  name   = "my-mysql-instance-policy"
  role   = aws_iam_role.mysql_instance.id

  policy = jsonencode({
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
      }
    ]
  })
}

resource "aws_iam_instance_profile" "mysql_instance" {
  name = "my-mysql-instance-profile"
  role = aws_iam_role.mysql_instance.name
}

resource "aws_security_group" "mysql_instance" {
  name        = "my-mysql-instance-sg"
  description = "Security group for MySQL instance"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "mysql_instance" {
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "password"
  vpc_security_group_ids = [aws_security_group.mysql_instance.id]
  db_name                = "my-mysql-instance" // Changed 'name' to 'db_name'
}