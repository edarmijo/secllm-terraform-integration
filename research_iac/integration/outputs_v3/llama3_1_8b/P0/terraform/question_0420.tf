provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "mysql_role" {
  name        = "mysql-role"
  description = "Role for MySQL instance"

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

resource "aws_iam_role_policy" "mysql_policy" {
  name   = "mysql-policy"
  role   = aws_iam_role.mysql_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:StartDBInstance",
          "rds:StopDBInstance",
          "rds:DeleteDBInstance",
          "rds:CreateDBInstance",
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances",
          "rds:DescribeDBInstanceAutomatedBackups",
          "rds:DescribeDBInstanceAutomatedBackups",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:DescribeDBSnapshots",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "mysql_snapshot_role" {
  name        = "mysql-snapshot-role"
  description = "Role for MySQL snapshot"

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

resource "aws_iam_role_policy" "mysql_snapshot_policy" {
  name   = "mysql-snapshot-policy"
  role   = aws_iam_role.mysql_snapshot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:DescribeDBSnapshots",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_db_instance" "mysql_instance" {
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = "db.t2.micro"
  name                   = "mydb"
  username               = "mydbuser"
  password               = "mydbpass"
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  skip_final_snapshot    = true
  iam_instance_profile   = aws_iam_role.mysql_role.name
}

resource "aws_db_instance" "mysql_snapshot" {
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = "db.t2.micro"
  name                   = "mysnapshot"
  username               = "mysnapshotuser"
  password               = "mysnapshotpass"
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  skip_final_snapshot    = true
  iam_instance_profile   = aws_iam_role.mysql_snapshot_role.name
  db_snapshot_identifier = aws_db_instance.mysql_instance.id
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Security group for MySQL instance"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}