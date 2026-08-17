provider "aws" {
  region = "us-west-2"
}

# Create a secret for the RDS instance
resource "aws_secretsmanager_secret" "rds_secret" {
  name = "rds-db-credentials"
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = "myuser"
    password = "mypassword"
  })
}

# Create an IAM role for the RDS instance
resource "aws_iam_role" "rds_role" {
  name        = "rds-execution-role"
  description = "Execution role for RDS instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM policy for the RDS instance
resource "aws_iam_policy" "rds_policy" {
  name        = "rds-execution-policy"
  description = "Policy for RDS instance execution"

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
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBSnapshots",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "rds_attach" {
  role       = aws_iam_role.rds_role.name
  policy_arn = aws_iam_policy.rds_policy.arn
}

# Create an RDS instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string).username
  password             = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string).password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
}

# Create a security group for the RDS instance
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
}

# Create a DB subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  description = "Subnet group for RDS instance"

  subnet_ids = [
    "subnet-12345678",
    "subnet-90123456",
  ]
}

# Create a snapshot of the RDS instance
resource "aws_db_snapshot" "rds_snapshot" {
  db_instance_identifier = aws_db_instance.rds_instance.id
  db_snapshot_identifier = "mydb-snapshot"
}